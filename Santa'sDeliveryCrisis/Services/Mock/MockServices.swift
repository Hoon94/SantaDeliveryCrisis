import Foundation

/// 화면 미리보기와 병렬 개발용 가짜 구현. 실제 구현이 준비되면 교체한다.
/// 미리보기용 샘플 데이터
enum MockData {
    static let question = Question(
        text: "다음 코드를 컴파일하면 어떻게 될까요?",
        codeSnippet: "let name = \"Swift\"\nname = \"Swift++\"",
        choices: ["정상 실행", "컴파일 오류", "크래시", "경고만 표시"],
        correctIndex: 1,
        explanation: "let으로 선언한 상수는 값을 바꿀 수 없습니다.",
        category: .swiftSyntax,
        difficulty: .easy,
        tags: ["let"],
        isSeed: true
    )

    static func session(answered: Int = 0) -> QuizSession {
        let session = QuizSession(
            task: .giftProduction,
            category: nil,
            difficulty: .easy,
            questionSnapshots: [QuestionSnapshot(question)],
            passThresholdPercent: 80
        )
        session.currentIndex = answered
        return session
    }
}

/// 항상 같은 카테고리를 추천하는 가짜 구현
struct MockTaskRecommender: TaskRecommending {
    var category: QuizCategory? = .swiftSyntax

    func recommendedCategory(sessions: [QuizSession]) -> QuizCategory? { category }
}

struct MockQuestionSelector: QuestionSelecting {
    func select(
        category: QuizCategory?, difficulty: Difficulty, tags: Set<String>,
        count: Int, questions: [Question], history: [QuizSession]
    ) -> [Question] {
        Array(questions.prefix(max(count, 0)))
    }

    func availableCount(category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, questions: [Question]) -> Int {
        questions.count
    }
}

/// 저장 없이 메모리에서만 동작하는 세션 관리자
final class MockSessionManager: SessionManaging {
    private var current: QuizSession?
    private let trees: any TreeManaging

    init(trees: (any TreeManaging)? = nil) {
        self.trees = trees ?? MockTreeManager()
    }

    func startSession(task: WorkshopTask, categories: Set<QuizCategory>, difficulty: Difficulty, tags: Set<String>, count: Int) throws -> QuizSession {
        guard resumableSession() == nil else { throw SessionError.sessionAlreadyInProgress }
        let stage = QuizStage(task: task, difficulty: difficulty)
        guard stage.isUnlocked(in: trees.currentTree().rewardMask) else {
            throw SessionError.stageLocked(stage.title)
        }
        let session = MockData.session()
        session.task = task
        session.category = categories.count == 1 ? categories.first : nil
        session.difficulty = difficulty
        current = session
        return session
    }

    func submit(answerIndex: Int, forQuestionAt questionIndex: Int, in session: QuizSession) throws -> SessionAnswer {
        guard session.questionSnapshots.indices.contains(questionIndex) else {
            throw MockError.invalidIndex
        }
        let snapshot = session.questionSnapshots[questionIndex]
        if let existing = session.answers.first(where: { $0.questionID == snapshot.questionID }) {
            return existing
        }
        let answer = SessionAnswer(
            questionID: snapshot.questionID,
            selectedIndex: answerIndex,
            isCorrect: answerIndex == snapshot.correctIndex
        )
        session.answers.append(answer)
        session.currentIndex = session.answers.count
        return answer
    }

    func finish(_ session: QuizSession) throws -> SessionResult {
        guard session.status != .abandoned else { throw SessionError.sessionNotInProgress }
        let correct = session.answers.filter(\.isCorrect).count
        let total = session.questionSnapshots.count
        let passed = Accuracy.meetsThreshold(correct: correct, total: total, thresholdPercent: session.passThresholdPercent)
        if session.status == .inProgress {
            guard session.questionSnapshots.allSatisfy({ snapshot in
                session.answers.contains { $0.questionID == snapshot.questionID }
            }) else { throw SessionError.notAllAnswered }
            if passed {
                let grant = try trees.grant(task: session.task, difficulty: session.difficulty)
                session.rewardOutcome = grant.rewardOutcome
                session.treeCompleted = grant.completedTree != nil
            } else {
                session.rewardOutcome = trees.currentTree().hasReward(task: session.task, difficulty: session.difficulty)
                    ? .alreadyEarned : .notEarned
            }
            session.earnedDecorations = session.rewardOutcome == .earned ? 1 : 0
            session.status = .completed
            session.finishedAt = Date()
        }
        return SessionResult(
            correctCount: correct, totalCount: total,
            accuracyPercent: Accuracy.percent(correct: correct, total: total), elapsed: session.elapsedSeconds,
            passedThreshold: passed, rewardOutcome: session.rewardOutcome,
            earnedDecorations: session.earnedDecorations, treeCompleted: session.treeCompleted,
            wrongAnswers: session.answers.filter { !$0.isCorrect }
        )
    }

    func resumableSession() -> QuizSession? {
        guard current?.status == .inProgress else { return nil }
        return current
    }

    func abandon(_ session: QuizSession) throws {
        session.status = .abandoned
    }

    func updateElapsed(_ seconds: TimeInterval, in session: QuizSession) throws {
        guard session.status == .inProgress, seconds.isFinite, seconds > session.elapsedSeconds else { return }
        session.elapsedSeconds = seconds
    }

    enum MockError: Error { case invalidIndex }
}

/// 메모리에서만 동작하는 트리 관리자
final class MockTreeManager: TreeManaging {
    private var tree = TreeRecord()
    private var completed: [TreeRecord] = []

    func currentTree() -> TreeRecord { tree }

    func grant(task: WorkshopTask, difficulty: Difficulty) throws -> TreeGrantResult {
        guard tree.recordReward(task: task, difficulty: difficulty) else {
            return TreeGrantResult(completedTree: nil, currentDecorationCount: tree.decorationCount, rewardOutcome: .alreadyEarned)
        }
        guard tree.decorationCount == TreeRecord.slotCount else {
            return TreeGrantResult(completedTree: nil, currentDecorationCount: tree.decorationCount, rewardOutcome: .earned)
        }
        let finished = tree
        finished.completedAt = Date()
        completed.append(finished)
        tree = TreeRecord()
        return TreeGrantResult(completedTree: finished, currentDecorationCount: 0, rewardOutcome: .earned)
    }

    func completedTrees() -> [TreeRecord] { completed }
}

/// 파일을 다루지 않는 미디어 관리자
struct MockMediaFileManager: MediaFileManaging {
    func store(from url: URL) throws -> String { url.lastPathComponent }
    func cleanUnreferencedFiles() throws {}
}
