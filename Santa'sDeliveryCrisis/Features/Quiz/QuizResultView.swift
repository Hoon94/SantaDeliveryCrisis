import SwiftUI

/// 세션 결과(S6). 새 보상이 있으면 획득 연출을, 재풀이·기준 미달이면 결과 카드만 보여 준다.
struct QuizResultView: View {
    let summary: QuizResultSummary
    let services: AppServices
    let onClose: () -> Void

    var body: some View {
        if summary.isSuccess {
            DecorationRevealView(
                summary: summary,
                style: OrnamentStyle(task: summary.task),
                feedback: services.feedback,
                onClose: onClose
            )
        } else {
            MissedDecorationView(summary: summary, feedback: services.feedback, onClose: onClose)
        }
    }
}

/// 새 보상이 없는 결과. 재풀이의 기준 통과 여부와 기존 장식 유지 사실을 별도로 표시한다.
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
                        OrnamentView(style: OrnamentStyle(task: summary.task), radiance: 0, size: min(proxy.size.width * 0.28, 120))
                            .rotationEffect(.degrees(sway), anchor: .top)
                            .saturation(0.6)
                        Text(summary.passedThreshold ? "기준을 통과했어요" : "이번에는 기준에 못 미쳤어요")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(Color.glowCore)
                            .multilineTextAlignment(.center)
                        Text(summary.rewardMessage)
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

#if DEBUG
#Preview("결과 · 재풀이 통과 · 추가 보상 없음") {
    QuizResultView(summary: .previewPracticePassed, services: .preview) {}
}

#Preview("결과 · 재풀이 미달 · 획득 장식 유지") {
    QuizResultView(summary: .previewPracticeFailed, services: .preview) {}
}
#endif
