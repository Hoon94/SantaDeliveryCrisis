import SwiftUI

/// 캐릭터의 기분. 문제 풀이 상태에 따라 바뀐다.
enum CharacterMood: Equatable {
    /// 기본. 숨 쉬듯 살짝 움직인다.
    case idle
    /// 보기를 고르는 중. 고개를 갸웃한다.
    case thinking
    /// 정답. 폴짝 뛰며 돈다.
    case happy
    /// 오답. 풀이 죽어 기운다.
    case sad
}

/// 테마 캐릭터. 지금은 이모지로 대신하고, 움직임과 말풍선만 실제와 같은 구조로 만든다.
/// `reactionToken`이 바뀔 때마다 같은 기분이어도 반응 동작을 처음부터 다시 재생한다.
// FIXME: [자산 교체] 이모지를 캐릭터 이미지로 교체. 움직임(KeyframeAnimator)은 그대로 쓴다.
struct ThemeCharacterView: View {
    let theme: QuizTheme
    let mood: CharacterMood
    let reactionToken: Int
    /// 말풍선 글. nil이면 숨긴다.
    let bubble: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Pose {
        var offsetY: CGFloat = 0
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        var rotation: Double = 0
        var spin: Double = 0
    }

    var body: some View {
        character
            .overlay(alignment: .topLeading) {
                if let bubble {
                    // 말풍선은 레이아웃에 영향을 주지 않고 캐릭터 위쪽 오른편에 띄운다.
                    SpeechBubble(text: bubble, tint: bubbleTint)
                        .fixedSize()
                        .offset(x: 44, y: -52)
                        .transition(.scale(scale: 0.5, anchor: .bottomLeading).combined(with: .opacity))
                }
            }
        .animation(.spring(response: 0.38, dampingFraction: 0.62), value: bubble)
        .accessibilityHidden(true)
    }

    private var bubbleTint: Color {
        switch mood {
        case .happy: .roomPositive
        case .sad: .roomNegative
        default: .nightSecondaryText
        }
    }

    private var character: some View {
        ZStack {
            // 발밑 그림자. 뛰어오를 때 작아진다.
            Ellipse()
                .fill(Color.inkShadow.opacity(0.28))
                .frame(width: 40, height: 9)
                .blur(radius: 3)
                .offset(y: 30)

            KeyframeAnimator(initialValue: Pose(), trigger: reactionToken) { pose in
                idleLayer(pose)
            } keyframes: { _ in
                keyframes
            }
            .overlay(alignment: .topTrailing) { sweat }
            .overlay { sparkles }
        }
        .frame(width: 64, height: 72)
    }

    /// 숨쉬기와 갸웃거림은 시간 함수로 계속 돌리고, 반응 동작은 그 위에 얹는다.
    private func idleLayer(_ pose: Pose) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let breathe = sin(t * 2.4) * 0.025
            let tilt = mood == .thinking ? sin(t * 1.8) * 7 : 0
            Text(theme.character)
                .font(.system(size: 52))
                .scaleEffect(x: (1 + breathe) * pose.scaleX, y: (1 - breathe) * pose.scaleY, anchor: .bottom)
                .rotationEffect(.degrees(tilt + pose.rotation), anchor: .bottom)
                .rotation3DEffect(.degrees(pose.spin), axis: (x: 0, y: 1, z: 0))
                .offset(y: pose.offsetY)
                .saturation(mood == .sad ? 0.55 : 1)
                .animation(.easeInOut(duration: 0.4), value: mood)
        }
    }

    /// 한 속성의 키프레임 하나: 도달할 값과 걸리는 시간
    private struct Beat {
        let value: Double
        let duration: Double
        init(_ value: Double, _ duration: Double) {
            self.value = value
            self.duration = duration
        }
    }

    /// 기분마다 속성별로 정확히 다섯 개의 키프레임을 갖는다. 키프레임 빌더는 조건 분기를 받지 못해서 값만 바꾼다.
    private struct PoseSpec {
        var scaleX: [Beat]
        var scaleY: [Beat]
        var offsetY: [Beat]
        var rotation: [Beat]
        var spin: [Beat]
    }

    private var spec: PoseSpec {
        let rest = [Beat(0, 0.01), Beat(0, 0.01), Beat(0, 0.01), Beat(0, 0.01), Beat(0, 0.01)]
        let one = [Beat(1, 0.01), Beat(1, 0.01), Beat(1, 0.01), Beat(1, 0.01), Beat(1, 0.01)]
        if reduceMotion { return PoseSpec(scaleX: one, scaleY: one, offsetY: rest, rotation: rest, spin: rest) }
        switch mood {
        case .happy:
            // 웅크렸다가 뛰어올라 한 바퀴 돌고 착지한다.
            return PoseSpec(
                scaleX: [Beat(1.12, 0.12), Beat(0.9, 0.18), Beat(1.0, 0.3), Beat(1.1, 0.1), Beat(1.0, 0.3)],
                scaleY: [Beat(0.82, 0.12), Beat(1.16, 0.18), Beat(1.0, 0.3), Beat(0.88, 0.1), Beat(1.0, 0.3)],
                offsetY: [Beat(0, 0.12), Beat(-36, 0.18), Beat(-30, 0.3), Beat(0, 0.1), Beat(0, 0.3)],
                rotation: rest,
                spin: [Beat(0, 0.12), Beat(120, 0.18), Beat(360, 0.3), Beat(360, 0.1), Beat(360, 0.3)]
            )
        case .sad:
            // 움찔하고 푹 처진다.
            return PoseSpec(
                scaleX: one,
                scaleY: [Beat(0.96, 0.1), Beat(0.94, 0.12), Beat(0.92, 0.12), Beat(0.9, 0.2), Beat(0.9, 0.3)],
                offsetY: [Beat(2, 0.1), Beat(3, 0.12), Beat(5, 0.12), Beat(8, 0.2), Beat(8, 0.3)],
                rotation: [Beat(-5, 0.08), Beat(5, 0.12), Beat(-4, 0.12), Beat(3, 0.12), Beat(-14, 0.4)],
                spin: rest
            )
        case .idle, .thinking:
            // 보기를 고를 때마다 톡 튄다.
            return PoseSpec(
                scaleX: one,
                scaleY: [Beat(0.92, 0.1), Beat(1.05, 0.12), Beat(0.98, 0.1), Beat(1.0, 0.1), Beat(1.0, 0.1)],
                offsetY: [Beat(0, 0.1), Beat(-9, 0.12), Beat(0, 0.1), Beat(0, 0.1), Beat(0, 0.1)],
                rotation: rest,
                spin: rest
            )
        }
    }

    @KeyframesBuilder<Pose> private var keyframes: some Keyframes<Pose> {
        let s = spec
        KeyframeTrack(\.scaleX) {
            CubicKeyframe(s.scaleX[0].value, duration: s.scaleX[0].duration)
            CubicKeyframe(s.scaleX[1].value, duration: s.scaleX[1].duration)
            CubicKeyframe(s.scaleX[2].value, duration: s.scaleX[2].duration)
            CubicKeyframe(s.scaleX[3].value, duration: s.scaleX[3].duration)
            CubicKeyframe(s.scaleX[4].value, duration: s.scaleX[4].duration)
        }
        KeyframeTrack(\.scaleY) {
            CubicKeyframe(s.scaleY[0].value, duration: s.scaleY[0].duration)
            CubicKeyframe(s.scaleY[1].value, duration: s.scaleY[1].duration)
            CubicKeyframe(s.scaleY[2].value, duration: s.scaleY[2].duration)
            CubicKeyframe(s.scaleY[3].value, duration: s.scaleY[3].duration)
            CubicKeyframe(s.scaleY[4].value, duration: s.scaleY[4].duration)
        }
        KeyframeTrack(\.offsetY) {
            CubicKeyframe(s.offsetY[0].value, duration: s.offsetY[0].duration)
            CubicKeyframe(s.offsetY[1].value, duration: s.offsetY[1].duration)
            CubicKeyframe(s.offsetY[2].value, duration: s.offsetY[2].duration)
            CubicKeyframe(s.offsetY[3].value, duration: s.offsetY[3].duration)
            CubicKeyframe(s.offsetY[4].value, duration: s.offsetY[4].duration)
        }
        KeyframeTrack(\.rotation) {
            CubicKeyframe(s.rotation[0].value, duration: s.rotation[0].duration)
            CubicKeyframe(s.rotation[1].value, duration: s.rotation[1].duration)
            CubicKeyframe(s.rotation[2].value, duration: s.rotation[2].duration)
            CubicKeyframe(s.rotation[3].value, duration: s.rotation[3].duration)
            CubicKeyframe(s.rotation[4].value, duration: s.rotation[4].duration)
        }
        KeyframeTrack(\.spin) {
            CubicKeyframe(s.spin[0].value, duration: s.spin[0].duration)
            CubicKeyframe(s.spin[1].value, duration: s.spin[1].duration)
            CubicKeyframe(s.spin[2].value, duration: s.spin[2].duration)
            CubicKeyframe(s.spin[3].value, duration: s.spin[3].duration)
            CubicKeyframe(s.spin[4].value, duration: s.spin[4].duration)
        }
    }

    /// 오답일 때 식은땀
    @ViewBuilder private var sweat: some View {
        if mood == .sad {
            Text("💧")
                .font(.system(size: 16))
                .offset(x: 4, y: 4)
                .transition(.scale.combined(with: .opacity))
                .id(reactionToken)
        }
    }

    /// 정답일 때 반짝이 세 개가 튀어 오른다.
    @ViewBuilder private var sparkles: some View {
        if mood == .happy && !reduceMotion {
            ForEach(0..<3, id: \.self) { i in
                SparkleBurst(index: i)
                    .id("\(reactionToken)-\(i)")
            }
        }
    }
}

/// 한 번 튀어 오르고 사라지는 반짝이
private struct SparkleBurst: View {
    let index: Int

    private struct Frame {
        var progress: CGFloat = 0
    }

    var body: some View {
        let angle = Double(index) * 2.0 * .pi / 3.0 - .pi / 2
        KeyframeAnimator(initialValue: Frame(), repeating: false) { frame in
            Text("✨")
                .font(.system(size: 14))
                .scaleEffect(frame.progress < 0.5 ? frame.progress * 2 : (1 - frame.progress) * 2)
                .opacity(frame.progress < 0.9 ? 1 : 0)
                .offset(x: cos(angle) * 36 * frame.progress, y: sin(angle) * 36 * frame.progress - 6)
        } keyframes: { _ in
            KeyframeTrack(\.progress) {
                LinearKeyframe(0, duration: 0.1 + 0.05 * Double(index))
                CubicKeyframe(1, duration: 0.7)
            }
        }
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

#Preview("기분별") {
    struct Demo: View {
        @State private var token = 0
        @State private var mood: CharacterMood = .idle
        @State private var bubble: String? = "안녕하세요!"
        var body: some View {
            VStack(spacing: 40) {
                ThemeCharacterView(theme: .wish, mood: mood, reactionToken: token, bubble: bubble)
                HStack {
                    ForEach([("대기", CharacterMood.idle), ("고민", .thinking), ("정답", .happy), ("오답", .sad)], id: \.0) { item in
                        Button(item.0) {
                            mood = item.1
                            token += 1
                            bubble = item.1 == .happy ? "정답!" : item.1 == .sad ? "아쉬워요" : nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(40)
            .background(ThemeBackground(theme: .wish))
        }
    }
    return Demo()
}
