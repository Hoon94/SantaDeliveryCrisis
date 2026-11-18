/// 화면 대신 세션 시작·복원·교체의 호출 순서를 관리한다.
struct StartSessionCoordinator {
    /// 화면이 표시하거나 이동해야 할 다음 단계.
    enum Outcome {
        /// 진행 중 세션을 이어 풀지 새로 시작할지 선택해야 한다.
        case needsResumeChoice(QuizSession)
        /// 생성하거나 이어 풀기로 선택한 세션으로 이동한다.
        case started(QuizSession)
        /// 후보가 부족하거나 서비스 호출이 실패했다.
        case failed
    }

    private let sessions: any SessionManaging
    private let selector: any QuestionSelecting

    /// 세션 관리자와 시작 전 후보 수를 확인할 선택기를 주입받는다.
    init(sessions: any SessionManaging, selector: any QuestionSelecting) {
        self.sessions = sessions
        self.selector = selector
    }

    /// 진행 중 세션이 있으면 선택을 요청하고, 없으면 눌린 카테고리 하나로 시작한다.
    func start(category: QuizCategory, filter: SelectFilter, questions: [Question]) -> Outcome {
        if let existing = sessions.resumableSession() {
            return .needsResumeChoice(existing)
        }
        guard canStart(category: category, filter: filter, questions: questions) else {
            return .failed
        }
        return createSession(category: category, filter: filter)
    }

    /// 기존 세션을 그대로 반환한다. 진행 위치와 팝업 설정은 변경하지 않는다.
    func resume(_ existing: QuizSession) -> Outcome {
        .started(existing)
    }

    /// 새 후보가 충분할 때만 기존 세션을 포기하고 새 세션을 시작한다.
    /// 포기가 실패하면 새 세션 생성은 호출하지 않는다.
    func restart(
        replacing existing: QuizSession,
        category: QuizCategory,
        filter: SelectFilter,
        questions: [Question]
    ) -> Outcome {
        guard canStart(category: category, filter: filter, questions: questions) else {
            return .failed
        }
        do {
            try sessions.abandon(existing)
        } catch {
            return .failed
        }
        return createSession(category: category, filter: filter)
    }

    private func canStart(
        category: QuizCategory, filter: SelectFilter, questions: [Question]
    ) -> Bool {
        // 사용자 결정: 후보 수가 요청 수보다 적으면 세션 생성과 기존 세션 포기를 막는다.
        DecorationAvailability.calculate(
            category: category, filter: filter, questions: questions, selector: selector
        ).isEnabled
    }

    private func createSession(category: QuizCategory, filter: SelectFilter) -> Outcome {
        do {
            let session = try sessions.startSession(
                category: category,
                difficulty: filter.difficulty,
                tags: [],
                count: filter.count
            )
            return .started(session)
        } catch {
            return .failed
        }
    }
}
