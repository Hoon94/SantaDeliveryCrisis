import SwiftUI

/// 두 자세가 가로로 배치된 캐릭터. 첫 보기 선택에서만 기본 자세에서 말하는 자세로 바뀐다.
struct ThemeCharacterView: View {
    let theme: QuizTheme
    let isSpeaking: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            Image(theme.characterImageName)
                .resizable()
                .interpolation(.none)
                .frame(width: proxy.size.width * 2, height: proxy.size.height)
                .offset(x: isSpeaking && !reduceMotion ? -proxy.size.width : 0)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .clipped()
        .transaction { $0.animation = nil }
        .accessibilityHidden(true)
    }
}

/// 꼬리가 달린 말풍선
struct SpeechBubble: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.nightPrimaryText)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.nightCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(tint.opacity(0.8), lineWidth: 1.5)
                    )
                    .shadow(color: Color.inkShadow.opacity(0.25), radius: 6, y: 3)
            )
            .overlay(alignment: .bottomLeading) {
                BubbleTail()
                    .fill(Color.nightCardBackground)
                    .overlay(BubbleTail().stroke(tint.opacity(0.8), lineWidth: 1.5))
                    .frame(width: 14, height: 9)
                    .offset(x: 12, y: 8)
            }
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX * 0.5, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview("캐릭터 두 자세") {
    VStack {
        ForEach(QuizTheme.allCases, id: \.self) { theme in
            HStack {
                ThemeCharacterView(theme: theme, isSpeaking: false)
                ThemeCharacterView(theme: theme, isSpeaking: true)
            }
            .frame(height: 120)
        }
    }
    .padding()
    .background(Color.nightBackgroundBottom)
}
