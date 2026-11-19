import SwiftData
import SwiftUI

/// 퀴즈 한 판의 전체 화면. 문제 풀이(S4), 피드백 시트(S5), 결과와 장식 연출(S6)을 이어 준다.
///
/// 사용: `fullScreenCover`에 `QuizFlowView(session: session) { dismiss() }`를 넣는다.
/// 나가기를 고르면 세션은 `inProgress`로 남아 "이어서 풀기"로 계속할 수 있다.
struct QuizFlowView: View {
    let session: QuizSession
    /// 화면을 닫아야 할 때(나가기, 결과의 [돌아가기]) 부른다.
    let onClose: () -> Void

    @Environment(\.services) private var services

    var body: some View {
        QuizFlowContent(session: session, services: services, onClose: onClose)
    }
}

/// `QuizFlowModel`을 만들어 쥐고 있는 안쪽 뷰. 환경의 서비스를 받은 뒤에 모델을 만들기 위해 둘로 나눴다.
private struct QuizFlowContent: View {
    @State private var model: QuizFlowModel
    private let services: AppServices
    private let onClose: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var isExitAlertShown = false

    init(session: QuizSession, services: AppServices, onClose: @escaping () -> Void) {
        _model = State(initialValue: QuizFlowModel(session: session, services: services))
        self.services = services
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            ThemeBackground(theme: model.theme)

            if model.phase == .result, let summary = model.summary {
                QuizResultView(summary: summary, services: services, onClose: onClose)
                    .transition(.opacity)
            } else {
                QuizQuestionView(model: model, services: services) {
                    isExitAlertShown = true
                }
                .transition(.opacity)

                if model.phase == .finishing {
                    ProgressView("결과를 계산하고 있어요")
                        .padding(24)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.nightCardBackground))
                        .foregroundStyle(Color.nightPrimaryText)
                }
            }
        }
        .animation(.easeInOut(duration: 0.45), value: model.phase == .result)
        .sheet(isPresented: feedbackBinding) { feedbackSheet }
        .alert("퀴즈를 그만할까요?", isPresented: $isExitAlertShown) {
            Button("나가기") { leave() }
            Button("계속 풀기", role: .cancel) {}
        } message: {
            Text(exitMessage)
        }
        .alert("문제가 생겼어요", isPresented: failedBinding) {
            Button("다시 시도") { model.retry() }
            Button("나가기", role: .cancel) { leave() }
        } message: {
            if case .failed(let message) = model.phase { Text(message) }
        }
        .onAppear { model.start() }
        .onDisappear { model.setActive(false) }
        .onChange(of: scenePhase) { _, newPhase in
            model.setActive(newPhase == .active)
        }
    }

    private var exitMessage: String { model.exitMessage }

    /// 시간을 저장한 뒤 화면을 닫는다. 세션은 `inProgress`로 남아 이어 풀 수 있다.
    private func leave() {
        model.prepareToLeave()
        onClose()
    }

    private var feedbackBinding: Binding<Bool> {
        Binding(
            get: { model.phase == .feedback },
            set: { _ in }
        )
    }

    private var failedBinding: Binding<Bool> {
        Binding(
            get: { if case .failed = model.phase { true } else { false } },
            set: { _ in }
        )
    }

    @ViewBuilder private var feedbackSheet: some View {
        if let snapshot = model.currentSnapshot, let isCorrect = model.isLastAnswerCorrect {
            QuizFeedbackSheet(
                isCorrect: isCorrect,
                snapshot: snapshot,
                isLast: model.isLastQuestion,
                theme: model.theme
            ) {
                model.advance()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
        }
    }
}

#if DEBUG
/// 미리보기에서 실제 서비스와 시드 문제로 5문제를 처음부터 끝까지 풀어 보는 도구.
/// 효과음과 진동도 실제로 나온다. 기준(80%)을 넘기려면 5문제 중 4문제를 맞혀야 한다.
private struct QuizFlowPreviewHost: View {
    let category: QuizCategory?
    @State private var environment = PreviewData.make()
    @State private var session: QuizSession?
    @State private var round = 0

    var body: some View {
        ZStack {
            if let session {
                QuizFlowView(session: session) { restart() }
                    .id(round)
            } else {
                ProgressView()
            }
        }
        .modelContainer(environment.container)
        .environment(\.services, environment.services)
        .task { start() }
    }

    private func start() {
        session = try? environment.services.sessions.startSession(
            category: category, difficulty: .easy, tags: [], count: 5
        )
    }

    /// 닫기를 누르면 새 세션으로 처음부터 다시 시작한다.
    private func restart() {
        if let session { try? environment.services.sessions.abandon(session) }
        round += 1
        start()
    }
}

#Preview("퀴즈 5문제 · 선물 생산") { QuizFlowPreviewHost(category: .swiftSyntax) }
#Preview("퀴즈 5문제 · 소원 접수") { QuizFlowPreviewHost(category: .aiUsage) }
#Preview("퀴즈 5문제 · 포장") { QuizFlowPreviewHost(category: .hig) }
#Preview("퀴즈 5문제 · 썰매 적재") { QuizFlowPreviewHost(category: .swiftUIPractice) }
#Preview("퀴즈 5문제 · 오늘의 출제") { QuizFlowPreviewHost(category: nil) }
#Preview("퀴즈 · 큰 글자") {
    QuizFlowPreviewHost(category: .swiftSyntax).dynamicTypeSize(.accessibility3)
}
#endif
