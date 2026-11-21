import SwiftUI

/// 보기 한 줄의 상태
enum QuizChoiceState: Equatable {
    /// 아직 고르지 않음
    case idle
    /// 고름(확인 전)
    case selected
    /// 채점 뒤 정답
    case correct
    /// 채점 뒤 내가 고른 오답
    case wrong
    /// 채점 뒤 나머지 보기
    case dimmed
}

/// 퀴즈 보기 버튼. 상태마다 색, 아이콘, 문구를 함께 바꿔서 색만으로 구분하지 않는다.
struct QuizChoiceButton: View {
    let index: Int
    let text: String
    let state: QuizChoiceState
    let theme: QuizTheme
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 오답 흔들림을 다시 재생하는 신호
    @State private var shakeToken = 0
    @State private var pulseToken = 0

    private static let letters = ["A", "B", "C", "D"]

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                badge
                Text(text)
                    .font(.body)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(background)
            .overlay(border)
            .overlay(alignment: .leading) { selectionGlow }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ChoicePressStyle())
        .opacity(state == .dimmed ? 0.5 : 1)
        .modifier(WrongShake(token: shakeToken, enabled: !reduceMotion))
        .keyframeAnimator(initialValue: 1.0, trigger: pulseToken) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(1.035, duration: 0.12)
                SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: state)
        .onChange(of: state) { _, newState in
            if newState == .wrong { shakeToken += 1 }
            if newState == .correct || newState == .selected { pulseToken += 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.letters[safe: index] ?? ""), \(text)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

    // MARK: - 조각

    /// 왼쪽 원. 평소에는 A~D, 채점 뒤에는 ✓ 또는 ✕ 아이콘으로 바뀐다.
    /// 원 크기가 그대로라서 상태가 바뀌어도 보기 글이 밀리지 않고, 정답과 오답은 색 외에 아이콘으로도 구분된다.
    private var badge: some View {
        ZStack {
            Circle()
                .fill(badgeFill)
                .frame(width: 32, height: 32)
            switch state {
            case .correct:
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(badgeText)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            case .wrong:
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(badgeText)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            default:
                Text(Self.letters[safe: index] ?? "")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(badgeText)
            }
        }
        .scaleEffect(state == .selected ? 1.08 : 1)
    }

    private var background: some View {
        ZStack {
            Color.roomCardBackground.opacity(0.88)
            switch state {
            case .selected: Color.roomAccent.opacity(0.16)
            case .correct: Color.roomPositive.opacity(0.18)
            case .wrong: Color.roomNegative.opacity(0.18)
            default: Color.clear
            }
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(borderColor, lineWidth: state == .idle || state == .dimmed ? 1 : 2.2)
    }

    /// 고른 보기는 왼쪽에서 번지는 공통 강조색으로 표시한다.
    @ViewBuilder private var selectionGlow: some View {
        if state == .selected {
            LinearGradient(colors: [Color.roomAccent.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: 90)
                .transition(.opacity)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle, .dimmed: .roomBorder
        case .selected: Color.roomAccent
        case .correct: .roomPositive
        case .wrong: .roomNegative
        }
    }

    private var textColor: Color {
        .roomPrimaryText
    }

    private var badgeFill: Color {
        switch state {
        case .selected: Color.roomAccent
        case .correct: .roomPositive
        case .wrong: .roomNegative
        default: .roomSubtleBackground
        }
    }

    private var badgeText: Color {
        switch state {
        case .selected: .roomOnAccentText
        case .correct, .wrong: .glowWhite
        default: .roomSecondaryText
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .idle, .dimmed: ""
        case .selected: "선택됨"
        case .correct: "정답"
        case .wrong: "오답"
        }
    }
}

/// 누르는 동안 살짝 작아지고 어두워지는 스타일
private struct ChoicePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// 오답일 때 좌우로 흔들린다. 토큰이 바뀔 때마다 처음부터 다시 흔든다.
private struct WrongShake: ViewModifier {
    let token: Int
    let enabled: Bool

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 0.0, trigger: token) { view, offset in
            view.offset(x: offset)
        } keyframes: { _ in
            KeyframeTrack {
                if enabled && token > 0 {
                    CubicKeyframe(-12, duration: 0.06)
                    CubicKeyframe(11, duration: 0.09)
                    CubicKeyframe(-8, duration: 0.09)
                    CubicKeyframe(6, duration: 0.08)
                    CubicKeyframe(-3, duration: 0.07)
                    SpringKeyframe(0, duration: 0.2)
                } else {
                    LinearKeyframe(0, duration: 0.01)
                }
            }
        }
    }
}

extension Array {
    /// 범위 밖이면 nil을 돌려주는 안전한 접근
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("보기 상태") {
    VStack(spacing: 10) {
        QuizChoiceButton(index: 0, text: "var", state: .idle, theme: .factory) {}
        QuizChoiceButton(index: 1, text: "let: 값을 바꿀 수 없는 상수를 선언해요", state: .selected, theme: .factory) {}
        QuizChoiceButton(index: 2, text: "func", state: .correct, theme: .factory) {}
        QuizChoiceButton(index: 3, text: "const", state: .wrong, theme: .factory) {}
        QuizChoiceButton(index: 3, text: "나머지 보기", state: .dimmed, theme: .factory) {}
    }
    .padding()
    .background(ThemeBackground(theme: .factory))
}
