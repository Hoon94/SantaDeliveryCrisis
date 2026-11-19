import SwiftUI

/// 세션 결과(S6). 정답률이 기준 이상이면 장식 획득 연출과 결과 카드, 미만이면 조용한 결과 카드를 보여 준다.
struct QuizResultView: View {
    let summary: QuizResultSummary
    let services: AppServices
    let onClose: () -> Void

    var body: some View {
        if summary.isSuccess {
            DecorationRevealView(
                summary: summary,
                style: OrnamentStyle(category: summary.category),
                feedback: services.feedback,
                onClose: onClose
            )
        } else {
            MissedDecorationView(summary: summary, feedback: services.feedback, onClose: onClose)
        }
    }
}

/// 기준에 못 미쳐 장식을 받지 못했을 때의 결과. 벌칙은 없으니 차분하게 알려 준다.
private struct MissedDecorationView: View {
    let summary: QuizResultSummary
    let feedback: QuizFeedbackPlaying
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                let t = timeline.date.timeIntervalSince(startDate)
                let appear = RevealMath.smooth(t / 0.6)
                let slide = reduceMotion ? RevealMath.smooth((t - 0.5) / 0.4) : RevealMath.spring(t - 0.5, damping: 8, frequency: 7)
                let maxHeight = proxy.size.height * 0.62
                let sway = reduceMotion ? 0 : sin(t * 1.3) * 3

                ZStack {
                    Color.revealScrim.opacity(0.82 * appear)

                    VStack(spacing: 10) {
                        OrnamentView(style: OrnamentStyle(category: summary.category), radiance: 0, size: min(proxy.size.width * 0.28, 120))
                            .rotationEffect(.degrees(sway), anchor: .top)
                            .saturation(0.6)
                        Text("이번에는 장식을 못 받았어요")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(Color.glowCore)
                            .multilineTextAlignment(.center)
                        Text("기준은 \(summary.thresholdPercent)%예요. 벌칙은 없으니 다시 도전해 보세요")
                            .font(.subheadline)
                            .foregroundStyle(Color.glowCore.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appear)
                    .offset(y: (1 - appear) * 12)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    .padding(.top, 70)

                    ResultPopupCard(summary: summary, tint: .nightAccent, shownFor: max(t - 0.5, 0)) {
                        feedback.play(.button)
                        onClose()
                    }
                    .environment(\.colorScheme, .dark)
                    .frame(maxWidth: 540)
                    .frame(maxHeight: maxHeight)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .offset(y: (1 - slide) * (maxHeight + 60))
                    .opacity(t > 0.5 ? 1 : 0)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                }
            }
        }
        .ignoresSafeArea()
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            feedback.play(.popup)
        }
    }
}

#if DEBUG
#Preview("결과 · 미달") {
    ZStack {
        ThemeBackground(theme: .factory)
        QuizResultView(summary: .previewFailure, services: .preview) {}
    }
}
#endif
