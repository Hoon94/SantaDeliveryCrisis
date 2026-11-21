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
            // 라이트 모드의 밝은 색상막이 픽셀 배경을 뿌옇게 덮지 않도록 농도를 낮춘다.
            .overlay(palette.backdrop.opacity(colorScheme == .light ? 0.15 : 0.5))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.55), value: theme)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("소원 접수 배경") {
    QuizProcessBackground(theme: .wish)
}
