import Foundation
import SwiftData

/// 세션 시작, 답 저장, 완료, 이어 풀기, 포기를 처리하고 SwiftData에 저장한다.
///
/// - 저장은 항상 한 번의 `save()`로 끝낸다. 실패하면 `rollback()`으로 바뀐 값을 되돌리고 오류를 던진다.
/// - 채점은 세션 시작 때 복사한 스냅샷(`questionSnapshots`)의 정답으로 한다. 원본 문제를 고치거나 지워도 영향이 없다.
/// - 정답률 기준은 세션을 시작할 때 설정값을 세션에 저장하고, 이후에는 그 값만 쓴다.
final class SessionManager: SessionManaging {
    private let context: ModelContext
    private let selector: QuestionSelecting
    private let trees: TreeManaging
    private let settings: SettingsStore
    private let media: MediaFileManaging?
    private let now: () -> Date

    /// - Parameters:
    ///   - context: 저장에 쓰는 ModelContext. `TreeManager`와 같은 것을 넘겨야 한 번의 저장으로 묶인다.
    ///   - selector: 문제 선택
    ///   - trees: 장식 지급
    ///   - settings: 정답률 기준을 읽는 설정
    ///   - media: 세션 종료 뒤 쓰지 않는 미디어 파일을 정리할 때 부른다. nil이면 정리하지 않는다.
    ///   - now: 현재 시각. 테스트에서 고정 값을 넘긴다.
    init(
        context: ModelContext,
        selector: QuestionSelecting,
        trees: TreeManaging,
        settings: SettingsStore,
        media: MediaFileManaging? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.context = context
        self.selector = selector
        self.trees = trees
        self.settings = settings
        self.media = media
        self.now = now
    }

    // MARK: - 시작

    /// 세션을 시작한다. 진행 중 세션이 이미 있으면 `sessionAlreadyInProgress`를 던진다.
    /// 화면은 먼저 `resumableSession()`으로 확인하고, 사용자가 "새로 시작"을 고르면 `abandon`을 부른 뒤 시작한다.
    func startSession(
        category: QuizCategory?,
        difficulty: Difficulty,
        tags: Set<String>,
        count: Int
    ) throws -> QuizSession {
        let sessions = try context.fetch(FetchDescriptor<QuizSession>())
        guard !sessions.contains(where: { $0.status == .inProgress }) else {
            throw SessionError.sessionAlreadyInProgress
        }

        let questions = try context.fetch(FetchDescriptor<Question>())
        let picked = selector.select(
            category: category,
            difficulty: difficulty,
            tags: tags,
            count: count,
            questions: questions,
            history: sessions
        )
        guard !picked.isEmpty else { throw SessionError.noCandidates }

        let session = QuizSession(
            category: category,
            difficulty: difficulty,
            questionSnapshots: picked.map { QuestionSnapshot($0) },
            passThresholdPercent: settings.passThresholdPercent,
            startedAt: now()
        )
        context.insert(session)
        try commit()
        return session
    }

    // MARK: - 답 저장

    /// `questionIndex`번째 문제(0부터)에 답을 저장한다.
    /// - 이미 답이 있는 문제면 처음 저장된 답을 그대로 돌려주고 새로 저장하지 않는다(값이 달라도 유지).
    /// - 앞선 문제 중 답하지 않은 것이 있으면 `previousQuestionUnanswered`를 던진다.
    /// - 답 저장과 `currentIndex` 갱신(`answers.count`와 같은 값)은 한 번의 저장으로 처리한다.
    func submit(answerIndex: Int, forQuestionAt questionIndex: Int, in session: QuizSession) throws -> SessionAnswer {
        guard session.status == .inProgress else { throw SessionError.sessionNotInProgress }
        guard session.questionSnapshots.indices.contains(questionIndex) else {
            throw SessionError.invalidQuestionIndex(questionIndex)
        }

        let snapshot = session.questionSnapshots[questionIndex]
        if let existing = session.answers.first(where: { $0.questionID == snapshot.questionID }) {
            return existing
        }

        let answeredIDs = Set(session.answers.map(\.questionID))
        let hasUnansweredBefore = session.questionSnapshots[..<questionIndex]
            .contains { !answeredIDs.contains($0.questionID) }
        guard !hasUnansweredBefore else { throw SessionError.previousQuestionUnanswered }

        guard snapshot.choices.indices.contains(answerIndex) else {
            throw SessionError.invalidAnswerIndex(answerIndex)
        }

        let answer = SessionAnswer(
            questionID: snapshot.questionID,
            selectedIndex: answerIndex,
            isCorrect: answerIndex == snapshot.correctIndex,
            answeredAt: now()
        )
        session.answers.append(answer)
        session.currentIndex = session.answers.count
        try commit()
        return answer
    }

    // MARK: - 완료

    /// 세션을 끝내고 결과를 돌려준다.
    /// - 이미 `completed`이면 저장된 결과만 돌려주고 장식을 다시 지급하지 않는다.
    /// - 모든 문제에 답이 저장되어 있어야 한다. 아니면 `notAllAnswered`를 던진다.
    /// - 정답률이 세션에 저장된 기준 이상이면 장식 1개를 지급한다. 비교는 정수로 정확하게 한다(79.5%는 80% 기준 미달).
    /// - 세션 완료, 장식 지급, 트리 갱신은 한 번의 저장으로 처리한다. 실패하면 전부 되돌리고 세션은 `inProgress`로 남는다.
    func finish(_ session: QuizSession) throws -> SessionResult {
        switch session.status {
        case .completed:
            return makeResult(for: session)
        case .abandoned:
            throw SessionError.sessionNotInProgress
        case .inProgress:
            break
        }

        let total = session.questionSnapshots.count
        let answeredIDs = Set(session.answers.map(\.questionID))
        guard session.questionSnapshots.allSatisfy({ answeredIDs.contains($0.questionID) }) else {
            throw SessionError.notAllAnswered
        }

        let correct = session.answers.filter(\.isCorrect).count
        let passed = total > 0 && correct * 100 >= session.passThresholdPercent * total
        let earned = passed ? 1 : 0

        do {
            let grant = try trees.grant(decorations: earned)
            session.status = .completed
            session.finishedAt = now()
            session.earnedDecorations = earned
            session.treeCompleted = grant.completedTree != nil
            try commit()
        } catch {
            context.rollback()
            throw error
        }

        try? media?.cleanUnreferencedFiles()
        return makeResult(for: session)
    }

    // MARK: - 이어 풀기와 포기

    /// 이어 풀 수 있는 진행 중 세션. 여러 개면 가장 최근에 시작한 것. 없으면 nil
    func resumableSession() -> QuizSession? {
        let sessions = (try? context.fetch(FetchDescriptor<QuizSession>())) ?? []
        return sessions
            .filter { $0.status == .inProgress }
            .max { $0.startedAt < $1.startedAt }
    }

    /// 진행 중 세션을 포기 처리한다. 이미 포기한 세션이면 아무것도 하지 않고, 완료된 세션이면 오류를 던진다.
    func abandon(_ session: QuizSession) throws {
        switch session.status {
        case .abandoned:
            return
        case .completed:
            throw SessionError.sessionNotInProgress
        case .inProgress:
            session.status = .abandoned
            session.finishedAt = now()
            try commit()
        }
    }

    // MARK: - 내부

    /// 저장한다. 실패하면 바뀐 값을 되돌리고 오류를 다시 던진다.
    private func commit() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    /// 저장된 세션 값으로 결과를 만든다. `earnedDecorations`와 `treeCompleted`는 다시 계산하지 않고 저장된 값을 읽는다.
    private func makeResult(for session: QuizSession) -> SessionResult {
        let total = session.questionSnapshots.count
        let answerByQuestion = Dictionary(
            session.answers.map { ($0.questionID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let answersInOrder = session.questionSnapshots.compactMap { answerByQuestion[$0.questionID] }
        let correct = answersInOrder.filter(\.isCorrect).count
        return SessionResult(
            correctCount: correct,
            totalCount: total,
            accuracyPercent: total == 0 ? 0 : correct * 100 / total,
            elapsed: session.elapsedSeconds,
            earnedDecorations: session.earnedDecorations,
            treeCompleted: session.treeCompleted,
            wrongAnswers: answersInOrder.filter { !$0.isCorrect }
        )
    }
}

/// 세션 처리 중 생기는 오류
enum SessionError: Error, LocalizedError, Equatable {
    /// 조건에 맞는 문제가 하나도 없음
    case noCandidates
    /// 진행 중인 세션이 이미 있음
    case sessionAlreadyInProgress
    /// 진행 중이 아닌 세션에 답 저장·완료·포기를 요청함
    case sessionNotInProgress
    /// 문제 번호가 범위를 벗어남
    case invalidQuestionIndex(Int)
    /// 보기 번호가 범위를 벗어남
    case invalidAnswerIndex(Int)
    /// 앞선 문제에 아직 답하지 않음
    case previousQuestionUnanswered
    /// 모든 문제에 답하지 않은 채 완료를 요청함
    case notAllAnswered

    var errorDescription: String? {
        switch self {
        case .noCandidates: "조건에 맞는 문제가 없습니다."
        case .sessionAlreadyInProgress: "진행 중인 세션이 이미 있습니다."
        case .sessionNotInProgress: "진행 중인 세션이 아닙니다."
        case .invalidQuestionIndex(let index): "문제 번호가 올바르지 않습니다: \(index)"
        case .invalidAnswerIndex(let index): "보기 번호가 올바르지 않습니다: \(index)"
        case .previousQuestionUnanswered: "앞선 문제에 먼저 답해야 합니다."
        case .notAllAnswered: "모든 문제에 답한 뒤에 끝낼 수 있습니다."
        }
    }
}
