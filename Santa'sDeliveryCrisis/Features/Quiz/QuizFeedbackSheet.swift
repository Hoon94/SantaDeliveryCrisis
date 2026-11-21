import SwiftUI

/// 정답/오답 피드백(S5). 채점 결과, 해설, 다음으로 가는 버튼.
/// 색만으로 구분하지 않도록 아이콘과 문구를 함께 쓴다.
struct QuizFeedbackSheet: View {
    let isCorrect: Bool
    let snapshot: QuestionSnapshot
    let isLast: Bool
    let theme: QuizTheme
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var palette: QuizPalette { QuizPalette(colorScheme: colorScheme) }
    @State private var appeared = false

    private var tint: Color { isCorrect ? .roomPositive : .roomNegative }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                badge
                    .padding(.top, 22)

                Text(isCorrect ? "정답이에요!" : "아쉬워요")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(tint)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                if !isCorrect {
                    correctAnswerRow
                }

                explanationCard

                Button(action: onNext) {
                    Text(isLast ? "결과 보기" : "다음 문제")
                }
                .buttonStyle(GlowButtonStyle(tint: palette.accent, usesQuizColors: true))
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(palette.cardBackground)
        .presentationBackground(palette.cardBackground)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.6).delay(0.05)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// 큰 원 안의 아이콘. 정답이면 퍼지는 고리가 한 번 지나간다.
    private var badge: some View {
        ZStack {
            if isCorrect && !reduceMotion {
                Circle()
                    .stroke(tint.opacity(appeared ? 0 : 0.7), lineWidth: 3)
                    .scaleEffect(appeared ? 1.9 : 0.8)
                    .animation(.easeOut(duration: 0.8), value: appeared)
            }
            Circle()
                .fill(LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .shadow(color: tint.opacity(0.5), radius: 14, y: 4)
            Image(systemName: isCorrect ? "checkmark" : "xmark")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Color.glowWhite)
                .symbolEffect(.bounce, value: appeared)
        }
        .frame(width: 68, height: 68)
        .scaleEffect(appeared ? 1 : 0.3)
        .accessibilityHidden(true)
    }

    private var correctAnswerRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.roomPositive)
            VStack(alignment: .leading, spacing: 2) {
                Text("정답")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.roomPositive)
                Text(correctChoiceText)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.roomPositive.opacity(0.13)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.roomPositive.opacity(0.5), lineWidth: 1))
    }

    private var correctChoiceText: String {
        let letters = ["A", "B", "C", "D"]
        let letter = letters[safe: snapshot.correctIndex] ?? ""
        let text = snapshot.choices[safe: snapshot.correctIndex] ?? ""
        return "\(letter). \(text)"
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("해설", systemImage: "text.book.closed.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(palette.secondaryText)
            Text(snapshot.explanation)
                .font(.callout)
                .foregroundStyle(palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(palette.subtleBackground))
    }
}
