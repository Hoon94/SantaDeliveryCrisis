import SwiftUI

/// 장식 획득 연출과 결과 팝업.
///
/// 평범한 장식이 가운데에 나타나 떨리며 빛이 모이고, 번쩍인 뒤 조각이 터지며 후광 속에 빛나는 장식이 나타난다.
/// 이어서 "장식 획득 성공!"이 뜨고, 장식이 위로 올라가며 정답률, 작업, 난이도 등을 담은 결과 카드가 올라온다.
/// 장면은 모두 시간의 함수(`RevealFrame`)이고, 소리와 진동은 같은 시간표로 예약한다.
struct DecorationRevealView: View {
    let summary: QuizResultSummary
    let style: OrnamentStyle
    let feedback: QuizFeedbackPlaying
    let onClose: () -> Void
    /// 연출 속도 배율. 1이 실제 속도이고, 미리보기에서 느리게 보려고 1보다 작게 준다.
    var timeScale: Double = 1
    /// 값이 있으면 시간을 그 순간에 고정한다. 미리보기에서 특정 장면만 따로 볼 때 쓴다.
    var debugTime: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.rewardFlight) private var rewardFlight
    @State private var startDate = Date()

    var body: some View {
        GeometryReader { proxy in
            let screenOrigin = proxy.frame(in: .global).origin
            TimelineView(.animation) { timeline in
                let t = debugTime ?? timeline.date.timeIntervalSince(startDate) * timeScale
                let frame = RevealFrame(t: t, size: proxy.size, reduced: reduceMotion)
                ZStack {
                    stage(frame)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .modifier(ShockwaveModifier(frame: frame))
                        .offset(frame.shake)

                    card(frame, size: proxy.size, screenOrigin: screenOrigin)
                }
            }
        }
        .ignoresSafeArea()
        .task { await runDirector() }
        .onDisappear { feedback.stop(.chargeUp) }
        .accessibilityElement(children: .contain)
    }

    // MARK: - 무대

    private func stage(_ f: RevealFrame) -> some View {
        ZStack {
            Color.revealScrim.opacity(f.scrimAlpha)

            // 후광: 번쩍인 뒤 천천히 도는 빛줄기
            if f.raysIntensity > 0.001 {
                Rectangle()
                    .fill(Color.glowGold)
                    .colorEffect(ShaderLibrary.godRays(
                        .float2(f.center), .float(f.t * (reduceMotion ? 0 : 1)), .float(f.raysIntensity),
                        .float(f.minSide * 0.7), .color(.glowGold)
                    ))
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }

            // 충전 중 달아오르는 중심 빛
            if f.orb.alpha > 0.002 {
                Rectangle()
                    .fill(Color.glowCore)
                    .colorEffect(ShaderLibrary.chargeOrb(
                        .float2(f.center), .float(f.orb.radius), .float(f.orb.pulse), .float(f.orb.heat),
                        .color(.glowGold), .color(.glowCore)
                    ))
                    .opacity(f.orb.alpha)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }

            // 입자
            if !reduceMotion {
                Canvas { context, size in
                    RevealParticles.drawCharge(&context, t: f.t - RevealFrame.chargeStart, center: f.center, reach: f.minSide)
                    RevealParticles.drawHaloRings(&context, t: f.impactT, center: f.center, speed: f.minSide * 1.1)
                    RevealParticles.drawBurst(&context, t: f.impactT, center: f.center)
                    RevealParticles.drawTwinkles(&context, t: f.t, center: f.center, radius: f.ornamentSize * 0.75, strength: f.twinkleStrength)
                }
                .allowsHitTesting(false)
            }

            // 장식
            OrnamentView(style: style, radiance: f.radiance, heat: f.heat, glint: f.glint, size: f.ornamentSize)
                .scaleEffect(f.ornamentScale)
                .rotationEffect(.degrees(f.jitter.degrees))
                .offset(f.jitter.offset)
                .opacity(f.ornamentOpacity)
                .position(f.center)
                .accessibilityLabel(f.radiance > 0.5 ? "\(summary.stage.title) 장식" : "장식")

            // 번쩍임
            if f.flashAlpha > 0.002 {
                ZStack {
                    Color.glowCore.opacity(f.flashAlpha * 0.55)
                    RadialGradient(
                        colors: [Color.glowCore, Color.glowGold.opacity(0.65), .clear],
                        center: UnitPoint(x: f.center.x / max(f.size.width, 1), y: f.center.y / max(f.size.height, 1)),
                        startRadius: 0,
                        endRadius: f.minSide * 0.9
                    )
                    .opacity(f.flashAlpha)
                }
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            }

            title(f)
        }
    }

    /// "장식 획득 성공!" 제목과 장식 이름
    private func title(_ f: RevealFrame) -> some View {
        let y = max(f.center.y - f.ornamentSize * 0.82 - 26, 90)
        return VStack(spacing: 6) {
            RevealTitle(text: "장식 획득 성공!", t: f.titleT, reduced: reduceMotion)
            Text("\(summary.stage.title) 장식")
                .font(.headline)
                .foregroundStyle(Color.glowCore)
                .shadow(color: Color.inkShadow.opacity(0.6), radius: 4, y: 1)
                .opacity(RevealMath.smooth((f.titleT - 0.5) / 0.4))
                .offset(y: (1 - RevealMath.smooth((f.titleT - 0.5) / 0.4)) * 8)
        }
        .position(x: f.size.width / 2, y: y)
        .allowsHitTesting(false)
    }

    // MARK: - 결과 카드

    private func card(_ f: RevealFrame, size: CGSize, screenOrigin: CGPoint) -> some View {
        let maxHeight = size.height * 0.62
        return ResultPopupCard(summary: summary, tint: style.tint, shownFor: max(f.cardT, 0)) {
            feedback.play(.button)
            launchFlight(from: f, screenOrigin: screenOrigin)
            onClose()
        }
        .environment(\.colorScheme, .dark)
        .frame(maxWidth: 540)
        .frame(maxHeight: maxHeight)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .offset(y: (1 - f.cardSlide) * (maxHeight + 60))
        .opacity(f.cardT > 0 ? 1 : 0)
        .frame(width: size.width, height: size.height, alignment: .bottom)
    }

    /// 닫기를 누른 순간의 장식 위치에서 작업실 트리로 날아가는 연출을 시작한다.
    /// 트리가 완성된 세션은 완성 연출이 따로 있어서 날리지 않는다.
    private func launchFlight(from f: RevealFrame, screenOrigin: CGPoint) {
        let result = summary.result
        guard !result.treeCompleted, result.earnedDecorations > 0 else { return }
        let end = TreeSlots.clampedCount(summary.treeDecorationCount)
        let start = max(end - result.earnedDecorations, 0)
        guard start < end else { return }
        rewardFlight.start(RewardFlightCenter.Flight(
            style: style,
            origin: CGPoint(x: screenOrigin.x + f.center.x, y: screenOrigin.y + f.center.y),
            size: f.ornamentSize * CGFloat(f.ornamentScale),
            slots: start..<end
        ))
    }

    // MARK: - 소리와 진동 시간표

    /// 연출과 같은 시간표로 소리와 진동을 예약한다. 화면이 사라지면 작업도 함께 취소된다.
    private func runDirector() async {
        let clock = ContinuousClock()
        let origin = clock.now
        func wait(until seconds: Double) async -> Bool {
            let target = origin.advanced(by: .seconds(seconds / max(timeScale, 0.01)))
            do { try await clock.sleep(until: target) } catch { return false }
            return !Task.isCancelled
        }

        if reduceMotion {
            guard await wait(until: RevealFrame.Reduced.swapAt) else { return }
            feedback.play(.reveal)
            guard await wait(until: RevealFrame.Reduced.dockAt) else { return }
            feedback.play(.popup)
            return
        }

        guard await wait(until: RevealFrame.chargeStart) else { return }
        feedback.play(.chargeUp)
        guard await wait(until: RevealFrame.impact) else { return }
        feedback.stop(.chargeUp)
        feedback.play(.impact)
        feedback.play(.burst)
        guard await wait(until: RevealFrame.impact + RevealFrame.titleDelay) else { return }
        feedback.play(summary.result.treeCompleted ? .treeComplete : .reveal)
        guard await wait(until: RevealFrame.dockAt) else { return }
        feedback.play(.popup)
    }
}

// MARK: - 충격파

/// 번쩍인 순간 화면을 물결처럼 밀어내는 GPU 효과. 충격파가 있는 동안에만 켠다.
private struct ShockwaveModifier: ViewModifier {
    let frame: RevealFrame

    func body(content: Content) -> some View {
        let shock = frame.shock
        content.layerEffect(
            ShaderLibrary.shockwave(
                .float2(frame.center),
                .float(shock?.radius ?? 0),
                .float(shock?.width ?? 1),
                .float(shock?.amplitude ?? 0),
                .float(shock?.aberration ?? 0)
            ),
            maxSampleOffset: CGSize(width: 80, height: 80),
            isEnabled: shock != nil
        )
    }
}

// MARK: - 제목

/// 글자가 하나씩 튀어 오르며 나타나는 제목. 금빛 그라데이션과 빛 번짐, 훑고 지나가는 반짝임이 있다.
private struct RevealTitle: View {
    let text: String
    /// 제목이 시작된 뒤 흐른 시간. 음수면 아직 안 나옴
    let t: Double
    let reduced: Bool

    var body: some View {
        let characters = Array(text)
        HStack(spacing: 0) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                let u = t - Double(index) * 0.05
                let pop = reduced ? RevealMath.smooth(u / 0.4) : RevealMath.spring(u, damping: 6, frequency: 13)
                Text(String(character))
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .scaleEffect(max(pop, 0), anchor: .bottom)
                    .offset(y: reduced ? 0 : (1 - min(pop, 1)) * 24)
                    .opacity(min(max(u * 6, 0), 1))
            }
        }
        .foregroundStyle(
            LinearGradient(colors: [.glowCore, .glowGold, .glowEmber], startPoint: .top, endPoint: .bottom)
        )
        .shadow(color: Color.inkShadow.opacity(0.85), radius: 0, y: 3)
        .shadow(color: Color.glowGold.opacity(0.9), radius: 16)
        .overlay { shine }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }

    /// 제목 위로 반짝이 줄기가 한 번 훑고 지나간다.
    @ViewBuilder private var shine: some View {
        let sweep = (t - 0.7) / 0.7
        if !reduced, sweep > 0, sweep < 1 {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color.glowWhite.opacity(0.9), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 46)
                .rotationEffect(.degrees(20))
                .offset(x: (sweep * 2 - 1) * 180)
                .blendMode(.plusLighter)
                .mask {
                    Text(text)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                }
        }
    }
}

// MARK: - 미리보기

#if DEBUG
/// 연출을 느리게 돌려 보거나 다시 재생해 보는 도구. 슬라이더로 원하는 순간에 멈춰 볼 수도 있다.
private struct RevealLab: View {
    @State private var run = 0
    @State private var scale = 1.0
    @State private var isScrubbing = false
    @State private var scrubTime = 3.2
    let style: OrnamentStyle
    let summary: QuizResultSummary

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ThemeBackground(theme: .wish)
            DecorationRevealView(
                summary: summary,
                style: style,
                feedback: isScrubbing ? SilentFeedbackPlayer() : FeedbackPlayer(settings: SettingsStore()),
                onClose: { run += 1 },
                timeScale: scale,
                debugTime: isScrubbing ? scrubTime : nil
            )
            .id(run)

            VStack(alignment: .trailing, spacing: 8) {
                Button("다시 재생") { isScrubbing = false; run += 1 }
                    .buttonStyle(.borderedProminent)
                Picker("속도", selection: $scale) {
                    Text("1x").tag(1.0)
                    Text("0.5x").tag(0.5)
                    Text("0.25x").tag(0.25)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
                .onChange(of: scale) { isScrubbing = false; run += 1 }
                Toggle("순간 고정", isOn: $isScrubbing)
                    .toggleStyle(.switch)
                    .fixedSize()
                if isScrubbing {
                    Slider(value: $scrubTime, in: 0...7.5)
                        .frame(width: 190)
                    Text(String(format: "%.2f초", scrubTime))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 50)
            .padding(.trailing, 12)
        }
    }
}

#Preview("획득 연출 · 소원 접수") {
    RevealLab(style: .task(.wishReception), summary: .previewSuccess)
}

#Preview("획득 연출 · 오늘의 출제(트리 완성)") {
    RevealLab(style: .mixed, summary: .previewTreeComplete)
}

#Preview("획득 연출 · 포장") {
    RevealLab(style: .task(.wrapping), summary: .previewSuccess)
}
#endif
