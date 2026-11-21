import SwiftUI

/// 화면의 주 버튼 스타일. 테마 색 그라데이션에 빛 번짐이 있고, 누르면 눌리며, 켜지는 순간 톡 튄다.
struct GlowButtonStyle: ButtonStyle {
    let tint: Color
    /// 풀이 화면은 모드별 퀴즈 팔레트를 사용하고, 결과 연출은 기존 색상을 유지한다.
    var usesQuizColors = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var palette: QuizPalette { QuizPalette(colorScheme: colorScheme) }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(isEnabled
                ? (usesQuizColors ? palette.onAccentText : Color.glowWhite)
                : (usesQuizColors ? palette.secondaryText : Color.nightSecondaryText))
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isEnabled
                            ? AnyShapeStyle(LinearGradient(colors: [tint, tint.opacity(0.78)], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(usesQuizColors ? palette.border : Color.nightBorder)
                    )
                    .overlay(alignment: .top) {
                        // 윗면 하이라이트
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [Color.glowWhite.opacity(isEnabled ? 0.55 : 0.1), .clear], startPoint: .top, endPoint: .center),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: isEnabled ? tint.opacity(configuration.isPressed ? 0.2 : 0.5) : .clear, radius: configuration.isPressed ? 4 : 14, y: configuration.isPressed ? 2 : 6)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.62), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.55), value: isEnabled)
            .scaleEffect(isEnabled ? 1 : 0.985)
    }
}

/// 둥근 아이콘 버튼(닫기, 힌트 등)
struct RoundIconButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var palette: QuizPalette { QuizPalette(colorScheme: colorScheme) }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 44, minHeight: 44)
            .background(Circle().fill(palette.cardBackground.opacity(0.85)))
            .overlay(Circle().strokeBorder(palette.border, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
