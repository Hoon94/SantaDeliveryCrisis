import SwiftUI

/// 풀이 화면의 픽셀 작업장. 기존 결과 화면의 배경과 독립적으로 표시한다.
struct QuizProcessBackground: View {
    let theme: QuizTheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(theme.backgroundName)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .overlay(Color.nightBackgroundTop.opacity(0.5))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("소원 접수 배경") {
    QuizProcessBackground(theme: .wish)
}
