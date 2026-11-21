import SwiftUI

/// 두 자세가 가로로 배치된 캐릭터. 첫 보기 선택에서만 기본 자세에서 말하는 자세로 바뀐다.
struct ThemeCharacterView: View {
    let theme: QuizTheme
    let isSpeaking: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let usesSpeakingPose = isSpeaking && !reduceMotion
            Image(theme.characterImageName)
                .resizable()
                .interpolation(.none)
                .frame(width: proxy.size.width * 2, height: proxy.size.height)
                .offset(x: usesSpeakingPose ? -proxy.size.width : 0)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
                .clipped()
                .offset(x: usesSpeakingPose ? proxy.size.width * theme.speakingHorizontalOffset : 0)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .clipped()
        .transaction { $0.animation = nil }
        .accessibilityHidden(true)
    }
}

/// 왼쪽 아래의 캐릭터를 향하는 꼬리가 달린 말풍선.
struct SpeechBubble: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.nightPrimaryText)
            .multilineTextAlignment(.leading)
            .padding(.leading, 22)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
            .background(
                SpeechBubbleShape()
                    .fill(Color.nightCardBackground)
                    .overlay(
                        SpeechBubbleShape()
                            .stroke(tint.opacity(0.8), lineWidth: 1.5)
                    )
                    .shadow(color: Color.inkShadow.opacity(0.25), radius: 6, y: 3)
            )
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// 말풍선 몸체와 꼬리를 하나로 그려 경계선이 겹치지 않게 한다.
private struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let left = rect.minX + 10
        let right = rect.maxX
        let top = rect.minY
        let bottom = rect.maxY
        let radius = min(14, rect.height / 4)
        // 여러 줄 대사에서도 꼬리는 아래쪽에 고정해 캐릭터의 머리 방향을 유지한다.
        let tailY = bottom - radius - 6
        var path = Path()
        path.move(to: CGPoint(x: left + radius, y: top))
        path.addLine(to: CGPoint(x: right - radius, y: top))
        path.addQuadCurve(to: CGPoint(x: right, y: top + radius), control: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: right - radius, y: bottom), control: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: left + radius, y: bottom))
        path.addQuadCurve(to: CGPoint(x: left, y: bottom - radius), control: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: left, y: tailY + 5))
        path.addLine(to: CGPoint(x: rect.minX, y: tailY + 5))
        path.addLine(to: CGPoint(x: left, y: tailY - 5))
        path.addLine(to: CGPoint(x: left, y: top + radius))
        path.addQuadCurve(to: CGPoint(x: left + radius, y: top), control: CGPoint(x: left, y: top))
        path.closeSubpath()
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
