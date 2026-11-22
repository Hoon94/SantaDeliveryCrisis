import SwiftData
import SwiftUI

/// 세션 결과(S6). 트리 완성·일반 장식 획득·새 보상 없음에 맞는 연출을 보여 준다.
struct QuizResultView: View {
    let summary: QuizResultSummary
    let services: AppServices
    let onClose: () -> Void
    @State private var showsReview = false

    var body: some View {
        Group {
            if summary.isSuccess {
                DecorationRevealView(
                    summary: summary,
                    style: OrnamentStyle(task: summary.task),
                    feedback: services.feedback,
                    onReview: openReview,
                    onClose: onClose
                )
            } else {
                MissedDecorationView(summary: summary, feedback: services.feedback, onReview: openReview, onClose: onClose)
            }
        }
        .sheet(isPresented: $showsReview) {
            QuizReviewView(summary: summary)
                .environment(\.services, services)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func openReview() {
        services.feedback.play(.button)
        showsReview = true
    }
}

/// 새 보상이 없는 결과. 재풀이의 기준 통과 여부와 기존 장식 유지 사실을 별도로 표시한다.
private struct MissedDecorationView: View {
    let summary: QuizResultSummary
    let feedback: QuizFeedbackPlaying
    let onReview: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                let t = timeline.date.timeIntervalSince(startDate)
                let appear = RevealMath.smooth(t / 0.6)
                let slide = reduceMotion ? RevealMath.smooth((t - 0.5) / 0.4) : RevealMath.spring(t - 0.5, damping: 8, frequency: 7)
                let sway = reduceMotion ? 0 : sin(t * 1.3) * 3

                ZStack {
                    Color.revealScrim.opacity(0.82 * appear)

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        VStack(spacing: 8) {
                            OrnamentView(style: OrnamentStyle(task: summary.task), radiance: 0, size: min(proxy.size.width * 0.2, 80))
                                .rotationEffect(.degrees(sway), anchor: .top)
                                .saturation(0.6)
                            Text(summary.passedThreshold ? "획득 조건을 충족했어요" : "이번에는 장식을 획득하지 못했어요")
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(Color.glowCore)
                                .multilineTextAlignment(.center)
                            Text(summary.rewardMessage)
                                .font(.subheadline)
                                .foregroundStyle(Color.glowCore.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 12)
                        .opacity(appear)
                        .offset(y: (1 - appear) * 12)
                        .padding(.top, max(proxy.safeAreaInsets.top + 12, 56))
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(2)

                        Spacer(minLength: 12)

                        ResultPopupCard(summary: summary, tint: .nightAccent, shownFor: max(t - 0.5, 0), onReview: onReview) {
                            feedback.play(.button)
                            onClose()
                        }
                        .environment(\.colorScheme, .dark)
                        .frame(maxWidth: 540)
                        .layoutPriority(1)
                        .offset(y: (1 - slide) * proxy.size.height)
                        .opacity(t > 0.5 ? 1 : 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 12, 24))
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
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
            .modelContainer(for: Question.self, inMemory: true)
    }
}

#Preview("결과 · 미달 · 큰 글자") {
    QuizResultView(summary: .previewFailure, services: .preview) {}
        .modelContainer(for: Question.self, inMemory: true)
        .dynamicTypeSize(.accessibility3)
}

#Preview("결과 · 미달 · 작은 화면", traits: .fixedLayout(width: 375, height: 667)) {
    QuizResultView(summary: .previewFailure, services: .preview) {}
        .modelContainer(for: Question.self, inMemory: true)
}
#endif

#if DEBUG
#Preview("결과 · 재풀이 통과 · 추가 보상 없음") {
    QuizResultView(summary: .previewPracticePassed, services: .preview) {}
        .modelContainer(for: Question.self, inMemory: true)
}

#Preview("결과 · 재풀이 미달 · 획득 장식 유지") {
    QuizResultView(summary: .previewPracticeFailed, services: .preview) {}
        .modelContainer(for: Question.self, inMemory: true)
}
#endif
