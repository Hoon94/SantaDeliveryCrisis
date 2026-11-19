import Foundation
import Observation

/// 퀴즈 한 판(S4, S5, S6)의 진행을 맡는다. 화면은 이 모델의 값을 그리고, 사용자의 동작을 이 모델에 전달한다.
///
/// - 채점과 저장은 `SessionManaging`에 맡기고, 이 모델은 어느 문제를 보여 줄지와 화면 상태만 관리한다.
/// - 문제 내용은 원본 `Question`이 아니라 세션이 시작할 때 복사한 `QuestionSnapshot`으로 그린다.
@MainActor @Observable
final class QuizFlowModel {
    /// 화면 단계
    enum Phase: Equatable {
        /// 문제를 풀고 있다.
        case answering
        /// 채점 결과(S5)를 보고 있다.
        case feedback
        /// 결과를 계산하고 있다.
        case finishing
        /// 결과 화면(S6)
        case result
        /// 결과 계산에 실패했다. 다시 시도할 수 있다.
        case failed(String)
    }

    let session: QuizSession
    private let services: AppServices

    /// 지금 보여 주는 문제 번호(0부터)
    private(set) var index: Int
    /// 고른 보기. 채점 뒤에는 저장된 답
    private(set) var selectedIndex: Int?
    private(set) var phase: Phase = .answering
    /// 방금 낸 답이 맞았는가
    private(set) var isLastAnswerCorrect: Bool?
    /// 힌트를 열었는가
    var isHintVisible = false
    /// 캐릭터의 기분과 반응 신호, 말풍선
    private(set) var mood: CharacterMood = .idle
    private(set) var reactionToken = 0
    private(set) var bubble: String?
    /// 결과 요약. `phase == .result`일 때만 있다.
    private(set) var summary: QuizResultSummary?

    // 소요 시간: 화면이 떠 있고 앱이 활성일 때만 쌓는다.
    private let baseElapsed: TimeInterval
    private var accumulated: TimeInterval = 0
    private var activeSince: Date?
    private var bubbleTask: Task<Void, Never>?
    private var verdictTask: Task<Void, Never>?

    /// - Parameters:
    ///   - session: 푸는 세션. 이미 답한 문제가 있으면 그 다음 문제부터 시작한다.
    ///   - services: 앱 서비스 묶음
    init(session: QuizSession, services: AppServices) {
        self.session = session
        self.services = services
        self.baseElapsed = session.elapsedSeconds
        self.index = min(session.answers.count, session.questionSnapshots.count)
    }

    // MARK: - 읽기 전용 값

    /// 문제 수
    var totalCount: Int { session.questionSnapshots.count }

    /// 지금 문제의 복사본. 범위를 벗어나면 nil
    var currentSnapshot: QuestionSnapshot? { session.questionSnapshots[safe: index] }

    /// 지금 문제의 테마
    var theme: QuizTheme {
        QuizTheme(category: session.category ?? currentSnapshot?.category ?? .aiUsage)
    }

    /// 진행률 0...1. 채점을 마친 문제까지 채운다.
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        let done = index + (phase == .feedback ? 1 : 0)
        return min(Double(done) / Double(totalCount), 1)
    }

    /// 마지막 문제인가
    var isLastQuestion: Bool { index >= totalCount - 1 }

    /// [확인]을 누를 수 있는가
    var canConfirm: Bool { phase == .answering && selectedIndex != nil }

    /// 보기의 현재 상태
    func choiceState(at choice: Int) -> QuizChoiceState {
        guard let snapshot = currentSnapshot else { return .idle }
        switch phase {
        case .answering:
            return selectedIndex == choice ? .selected : .idle
        case .feedback, .finishing, .result, .failed:
            if choice == snapshot.correctIndex { return .correct }
            if choice == selectedIndex { return .wrong }
            return .dimmed
        }
    }

    /// 지금까지 쓴 시간(초)
    var elapsed: TimeInterval {
        baseElapsed + accumulated + (activeSince.map { Date().timeIntervalSince($0) } ?? 0)
    }

    // MARK: - 시작과 시간

    /// 화면이 나타날 때 부른다. 모든 문제에 답한 세션을 이어 푸는 경우 곧바로 결과를 계산한다.
    func start() {
        setActive(true)
        if totalCount > 0, session.answers.count >= totalCount || session.status == .completed {
            finish()
        }
    }

    /// 화면이 떠 있고 앱이 활성일 때 true로 부른다. 시간 쌓기를 시작하거나 멈춘다.
    func setActive(_ isActive: Bool) {
        if isActive {
            if activeSince == nil { activeSince = Date() }
        } else if let since = activeSince {
            accumulated += Date().timeIntervalSince(since)
            activeSince = nil
            syncElapsed()
        }
    }

    /// 지금까지의 누적 시간을 서비스에 저장한다. 답을 낸 직후, 앱이 백그라운드로 갈 때, 결과를 계산하기 직전에 부른다.
    /// 시간 저장에 실패해도 풀이를 막지 않는다. 다음 호출에서 누적 총합을 다시 저장한다.
    private func syncElapsed() {
        try? services.sessions.updateElapsed(elapsed, in: session)
    }

    // MARK: - 풀이

    /// 보기를 고른다. 확인 전에는 몇 번이든 바꿀 수 있다.
    func select(_ choice: Int) {
        guard phase == .answering, let snapshot = currentSnapshot, snapshot.choices.indices.contains(choice) else { return }
        if selectedIndex != choice {
            services.feedback.play(.select)
        }
        selectedIndex = choice
        mood = .thinking
        reactionToken += 1
        showBubble(theme.thinkingLines.randomElement(), for: 2.2)
    }

    /// 힌트를 열고 닫는다. 점수와 보상에는 영향이 없다.
    func toggleHint() {
        guard phase == .answering else { return }
        services.feedback.play(.hint)
        isHintVisible.toggle()
    }

    /// [확인]. 답을 저장하고 채점 결과를 보여 준다.
    func confirm() {
        guard phase == .answering, let choice = selectedIndex, currentSnapshot != nil else { return }
        syncElapsed()
        do {
            let answer = try services.sessions.submit(answerIndex: choice, forQuestionAt: index, in: session)
            // 이미 저장된 답이 있으면 처음 저장된 답이 돌아온다. 화면도 그 답을 따른다.
            selectedIndex = answer.selectedIndex
            let isCorrect = answer.isCorrect
            isLastAnswerCorrect = isCorrect
            phase = .feedback
            isHintVisible = false

            services.feedback.play(.confirm)
            verdictTask?.cancel()
            verdictTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(130))
                guard !Task.isCancelled, let self else { return }
                self.services.feedback.play(isCorrect ? .correct : .wrong)
            }

            mood = isCorrect ? .happy : .sad
            reactionToken += 1
            let lines = isCorrect ? theme.correctLines : theme.wrongLines
            showBubble(lines.randomElement(), for: 3)
        } catch {
            phase = .failed("답을 저장하지 못했어요. 잠시 뒤 다시 시도해 주세요.")
        }
    }

    /// 피드백을 닫고 다음 문제로 간다. 마지막 문제였다면 결과를 계산한다.
    func advance() {
        guard phase == .feedback else { return }
        services.feedback.play(.next)
        if isLastQuestion {
            finish()
        } else {
            index += 1
            selectedIndex = nil
            isLastAnswerCorrect = nil
            mood = .idle
            bubble = nil
            phase = .answering
        }
    }

    /// 결과 계산에 실패했을 때 다시 시도한다.
    func retry() {
        if session.answers.count >= totalCount {
            finish()
        } else {
            phase = .answering
        }
    }

    // MARK: - 끝내기

    private func finish() {
        phase = .finishing
        setActive(false)
        syncElapsed()
        do {
            let result = try services.sessions.finish(session)
            let treeCount = result.treeCompleted ? TreeRecord.slotCount : services.trees.currentTree().decorationCount
            summary = QuizResultSummary(
                result: result,
                category: session.category,
                difficulty: session.difficulty,
                thresholdPercent: session.passThresholdPercent,
                treeDecorationCount: treeCount
            )
            phase = .result
        } catch {
            phase = .failed("결과를 계산하지 못했어요. 풀이는 저장되어 있어요.")
        }
    }

    // MARK: - 내부

    private func showBubble(_ text: String?, for seconds: Double) {
        bubbleTask?.cancel()
        bubble = text
        guard text != nil else { return }
        bubbleTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.bubble = nil
        }
    }
}
