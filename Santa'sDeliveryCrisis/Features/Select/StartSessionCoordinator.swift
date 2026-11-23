/// 화면 대신 세션 시작·복원·교체의 호출 순서를 관리한다.
struct StartSessionCoordinator {
    /// 화면이 표시하거나 이동해야 할 다음 단계.
    enum Outcome {
        /// 진행 중 세션을 이어 풀지 새로 시작할지 선택해야 한다.
        case needsResumeChoice(QuizSession)
        /// 이미 보상을 보유한 작업·난이도이므로 재풀이 확인이 필요하다.
        case needsPracticeConfirmation
        /// 생성하거나 이어 풀기로 선택한 세션으로 이동한다.
        case started(QuizSession)
        /// 후보가 부족하거나 세션 생성·포기 호출이 실패했다.
        case failed
        /// 선행 보상이 없어 선택한 단계에 들어갈 수 없다.
        case locked(QuizStage)
    }

    private let sessions: any SessionManaging
    private let selector: any QuestionSelecting

    /// 세션 관리자와 시작 전 후보 수를 확인할 선택기를 주입받는다.
    /// - Parameters:
    ///   - sessions: 진행 중 세션 조회·생성·포기를 담당하는 서비스.
    ///   - selector: 카테고리와 난이도에 맞는 후보 수를 조회하는 서비스.
    init(sessions: any SessionManaging, selector: any QuestionSelecting) {
        self.sessions = sessions
        self.selector = selector
    }

    /// 진행 중 세션이 있으면 선택을 요청하고, 없으면 선택한 카테고리들에서 고르게 섞어 시작한다.
    /// 작업은 보상 대상을 정하며, 문제는 선택한 카테고리 전체에서 고른다.
    /// - Parameters:
    ///   - filter: 마지막으로 적용한 출제 설정.
    ///   - questions: 시작 가능 여부를 확인할 현재 문제 목록.
    /// - Returns: 기존 세션 선택 요청, 새 세션, 또는 오류를 처리한 실패 결과.
    func start(
        task: WorkshopTask, filter: SelectFilter, questions: [Question],
        currentTree: TreeRecord?, allowsPractice: Bool = false
    ) -> Outcome {
        let stage = QuizStage(task: task, difficulty: filter.difficulty)
        guard stage.isUnlocked(in: currentTree?.rewardMask ?? 0) else { return .locked(stage) }
        if let existing = sessions.resumableSession() {
            return .needsResumeChoice(existing)
        }
        guard canStart(filter: filter, questions: questions) else {
            return .failed
        }
        if currentTree?.hasReward(task: task, difficulty: filter.difficulty) == true, !allowsPractice {
            return .needsPracticeConfirmation
        }
        return createSession(task: task, filter: filter)
    }

    /// 기존 세션을 그대로 반환한다. 진행 위치와 팝업 설정은 변경하지 않는다.
    /// - Parameter existing: 사용자가 이어 풀기로 선택한 기존 세션.
    /// - Returns: 기존 세션으로 진입하는 결과. 서비스의 상태는 바꾸지 않는다.
    func resume(_ existing: QuizSession) -> Outcome {
        .started(existing)
    }

    /// 새 후보가 충분할 때만 기존 세션을 포기하고 새 세션을 시작한다.
    /// 포기가 실패하면 새 세션 생성은 호출하지 않는다.
    /// - Parameters:
    ///   - existing: 새 세션 생성 전에 포기할 세션.
    ///   - filter: 장식을 눌렀을 때 적용되어 있던 출제 설정.
    ///   - questions: 후보 수를 확인할 현재 문제 목록.
    /// - Returns: 새 세션 또는 실패 결과. 포기 성공 후 생성 실패는 되돌리지 않는다.
    func restart(
        replacing existing: QuizSession,
        task: WorkshopTask,
        filter: SelectFilter,
        questions: [Question],
        currentTree: TreeRecord?, allowsPractice: Bool = false
    ) -> Outcome {
        let stage = QuizStage(task: task, difficulty: filter.difficulty)
        guard stage.isUnlocked(in: currentTree?.rewardMask ?? 0) else { return .locked(stage) }
        guard canStart(filter: filter, questions: questions) else {
            return .failed
        }
        // 재풀이 확인을 취소했을 때 기존 세션을 잃지 않도록 포기 전에 확인한다.
        if currentTree?.hasReward(task: task, difficulty: filter.difficulty) == true, !allowsPractice {
            return .needsPracticeConfirmation
        }
        do {
            try sessions.abandon(existing)
        } catch {
            return .failed
        }
        return createSession(task: task, filter: filter)
    }

    private func canStart(filter: SelectFilter, questions: [Question]) -> Bool {
        // 사용자 결정: 후보 수가 요청 수보다 적으면 세션 생성과 기존 세션 포기를 막는다.
        // 문제는 눌린 장식이 아니라 선택한 카테고리 전체에서 고르므로 후보도 합산해서 센다.
        selector.availableCount(
            categories: filter.categories, difficulty: filter.difficulty, tags: [], questions: questions
        ) >= filter.count
    }

    private func createSession(task: WorkshopTask, filter: SelectFilter) -> Outcome {
        do {
            let session = try sessions.startSession(
                task: task,
                categories: filter.categories,
                difficulty: filter.difficulty,
                tags: [],
                count: filter.count
            )
            return .started(session)
        } catch SessionError.stageLocked(_) {
            return .locked(QuizStage(task: task, difficulty: filter.difficulty))
        } catch {
            return .failed
        }
    }
}
