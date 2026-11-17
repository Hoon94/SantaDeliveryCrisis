import SwiftUI

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
            category: nil,
            difficulty: .easy,
            questionSnapshots: [QuestionSnapshot(question)],
            passThresholdPercent: 80
        )
        session.currentIndex = answered
        return session
    }
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

    func startSession(category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, count: Int) throws -> QuizSession {
        let session = MockData.session()
        session.category = category
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
        let correct = session.answers.filter(\.isCorrect).count
        let total = session.questionSnapshots.count
        let percent = total == 0 ? 0 : Int((Double(correct) / Double(total) * 100).rounded())
        session.status = .completed
        return SessionResult(
            correctCount: correct,
            totalCount: total,
            accuracyPercent: percent,
            elapsed: session.elapsedSeconds,
            earnedDecorations: percent >= session.passThresholdPercent ? 1 : 0,
            treeCompleted: false,
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

    enum MockError: Error { case invalidIndex }
}

/// 메모리에서만 동작하는 트리 관리자
final class MockTreeManager: TreeManaging {
    private var tree = TreeRecord()
    private var completed: [TreeRecord] = []

    func currentTree() -> TreeRecord { tree }

    func grant(decorations: Int) throws -> TreeGrantResult {
        tree.decorationCount += decorations
        guard tree.decorationCount >= TreeRecord.slotCount else {
            return TreeGrantResult(completedTree: nil, currentDecorationCount: tree.decorationCount)
        }
        let finished = tree
        finished.decorationCount = TreeRecord.slotCount
        finished.completedAt = Date()
        completed.append(finished)
        tree = TreeRecord()
        return TreeGrantResult(completedTree: finished, currentDecorationCount: 0)
    }

    func completedTrees() -> [TreeRecord] { completed }
}

/// 아무것도 재생하지 않는 피드백
struct MockFeedbackPlayer: FeedbackPlaying {
    func playCorrect() {}
    func playWrong() {}
    func playTreeComplete() {}
}

/// 파일을 다루지 않는 미디어 관리자
struct MockMediaFileManager: MediaFileManaging {
    func store(from url: URL) throws -> String { url.lastPathComponent }
    func cleanUnreferencedFiles() throws {}
}

/// 장면이 하나도 없는 저장소
struct MockTraceSceneRegistry: TraceSceneRegistry {
    func scene(for animationID: String) -> (steps: [TraceStep], view: AnyView)? { nil }
}
