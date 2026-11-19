import SwiftUI

/// 테마별 임시 배경. 작업 이름을 흐릿하게 크게 박고, 테마 색 빛 번짐과 천천히 떠다니는 눈송이를 깐다.
// FIXME: [자산 교체] 테마별 배경 일러스트가 오면 이 뷰 안을 이미지로 교체한다. 바깥 사용처는 그대로 둔다.
struct ThemeBackground: View {
    let theme: QuizTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.nightBackgroundTop, .nightBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            // 테마 색 빛 번짐 두 덩어리
            RadialGradient(
                colors: [theme.accent.opacity(0.42), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 420
            )
            RadialGradient(
                colors: [theme.accent.opacity(0.22), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 380
            )

            watermark
            props
            Snowfall(isAnimated: !reduceMotion)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: theme)
        .accessibilityHidden(true)
    }

    /// 작업 이름을 비스듬히 크게. 읽는 글자가 아니라 분위기용이라 아주 옅게 둔다.
    private var watermark: some View {
        GeometryReader { proxy in
            Text(theme.title)
                .font(.system(size: min(proxy.size.width * 0.34, 150), weight: .black, design: .rounded))
                .foregroundStyle(Color.nightPrimaryText.opacity(0.06))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .fixedSize()
                .rotationEffect(.degrees(-14))
                .blur(radius: 1.2)
                .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.34)
                .id(theme)
                .transition(.opacity)
        }
    }

    /// 테마 소품 이모지를 흐리게 흩어 둔다.
    private var props: some View {
        GeometryReader { proxy in
            ForEach(Array(theme.props.enumerated()), id: \.offset) { index, symbol in
                let x = [0.18, 0.82, 0.62][index % 3]
                let y = [0.24, 0.6, 0.86][index % 3]
                Text(symbol)
                    .font(.system(size: 54))
                    .opacity(0.10)
                    .blur(radius: 2)
                    .rotationEffect(.degrees(Double(index) * 17 - 14))
                    .position(x: proxy.size.width * x, y: proxy.size.height * y)
            }
            .id(theme)
            .transition(.opacity)
        }
    }
}

/// 천천히 떨어지는 눈송이. 모션 줄이기가 켜져 있으면 멈춘 채로 둔다.
private struct Snowfall: View {
    let isAnimated: Bool

    private struct Flake {
        let x: Double
        let speed: Double
        let size: Double
        let phase: Double
        let sway: Double
    }

    private static let flakes: [Flake] = {
        var rng = SeededRandom(seed: 7)
        return (0..<34).map { _ in
            Flake(
                x: rng.next(),
                speed: 0.018 + rng.next() * 0.04,
                size: 1.6 + rng.next() * 3.4,
                phase: rng.next(),
                sway: 6 + rng.next() * 16
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isAnimated)) { timeline in
            let t = isAnimated ? timeline.date.timeIntervalSinceReferenceDate : 0
            Canvas { context, size in
                for flake in Self.flakes {
                    let progress = (flake.phase + t * flake.speed).truncatingRemainder(dividingBy: 1)
                    let y = progress * (size.height + 20) - 10
                    let x = flake.x * size.width + sin(t * 0.7 + flake.phase * 20) * flake.sway
                    let rect = CGRect(x: x, y: y, width: flake.size, height: flake.size)
                    context.opacity = 0.18 + 0.28 * (flake.size / 5)
                    context.fill(Path(ellipseIn: rect), with: .color(.glowWhite))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("테마 4종") {
    HStack(spacing: 0) {
        ForEach(QuizTheme.allCases, id: \.self) { theme in
            ThemeBackground(theme: theme)
        }
    }
}
