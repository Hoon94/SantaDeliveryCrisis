import SwiftUI

/// 풀이 화면의 픽셀 작업장. 기존 결과 화면의 배경과 독립적으로 표시한다.
struct QuizProcessBackground: View {
    let theme: QuizTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var palette: QuizPalette { QuizPalette(colorScheme: colorScheme) }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(theme.backgroundName)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .id(theme)
                    .transition(.opacity)
            }
            // 라이트·다크 모두 같은 농도의 색상막을 덮어 글자와 배경을 구분한다.
            .overlay(palette.backdrop.opacity(0.5))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.55), value: theme)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("소원 접수 배경") {
    QuizProcessBackground(theme: .wish)
}
