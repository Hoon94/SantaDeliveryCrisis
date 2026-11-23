import SwiftUI

/// 결과 화면에서 [돌아가기]를 누른 장식이 작업실 트리의 빈 칸으로 날아가 흡수되는 연출.
///
/// 앱의 탭 구성 위에 가장 위 층으로 올려 두고, `RewardFlightCenter`에 비행이 있을 때만 그린다.
/// 장면은 모두 시간의 함수다. 출발 시각과 시간표(`RewardFlightMath`)만 알면 어느 순간이든 같은 장면을 그린다.
/// 소리와 진동은 같은 시간표로 예약한다.
///
/// 한 장식의 흐름
/// 1. 모으기: 결과 화면과 같은 자리에서 빛이 모인다. 퀴즈 화면이 페이드로 닫히는 동안 이어진다.
/// 2. 비행: 휘어진 길을 따라 점점 빨라지며 꼬리빛과 반짝임을 흘린다("슝").
/// 3. 흡수: 칸에 닿는 순간 번쩍이고(셰이더), 고리와 별빛이 퍼지며 장식이 칸에 스며든다.
///
/// 모션 줄이기가 켜져 있으면 곡선, 꼬리, 번쩍임을 빼고 짧게 이동하며 사라진다.
struct RewardFlightOverlay: View {
    @Environment(\.rewardFlight) private var center
    @Environment(\.services) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 비행 신호를 받은 시각
    @State private var launchDate = Date()
    /// 출발한 시각. nil이면 아직 모으는 중이거나 트리 위치를 기다리는 중
    @State private var departDate: Date?

    var body: some View {
        GeometryReader { proxy in
            let overlayOrigin = proxy.frame(in: .global).origin
            ZStack {
                if let flight = center.flight {
                    TimelineView(.animation) { timeline in
                        scene(flight, now: timeline.date, overlayOrigin: overlayOrigin, size: proxy.size)
                    }
                    .id(flight.id)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: center.flight?.id) { await run() }
    }

    // MARK: - 시간표 진행(소리, 진동, 숨김 해제)

    private func run() async {
        guard let flight = center.flight else { return }
        launchDate = Date()
        departDate = nil

        let gather = reduceMotion ? RewardFlightMath.Reduced.gather : RewardFlightMath.gather
        let flightTime = reduceMotion ? RewardFlightMath.Reduced.flight : RewardFlightMath.flight
        let stagger = reduceMotion ? 0.12 : RewardFlightMath.stagger

        // 모으기가 끝나고 트리 위치를 알게 될 때까지 기다린다. 끝내 못 찾으면 연출을 접고 트리를 그대로 보여 준다.
        let giveUpAt = launchDate.addingTimeInterval(2.5)
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(launchDate)
            if elapsed >= gather, center.hasTreeFrame { break }
            if Date() > giveUpAt {
                center.finish()
                return
            }
            try? await Task.sleep(for: .milliseconds(16))
        }
        guard !Task.isCancelled else { return }

        let depart = Date()
        departDate = depart
        services.feedback.play(.launch)

        for index in 0..<flight.count {
            let landAt = depart.addingTimeInterval(
                RewardFlightMath.landTime(index, flight: flightTime, stagger: stagger) + RewardFlightMath.fillDelay
            )
            let wait = landAt.timeIntervalSinceNow
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            guard !Task.isCancelled else { return }
            center.landOne()
            services.feedback.play(.absorb)
        }

        let endAt = depart.addingTimeInterval(RewardFlightMath.totalDuration(count: flight.count, reduced: reduceMotion))
        let wait = endAt.timeIntervalSinceNow
        if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
        guard !Task.isCancelled else { return }
        center.finish()
    }

    // MARK: - 장면

    private enum Phase {
        /// 출발 전. 값은 모으기 진행도 0...1
        case hold(gather: Double)
        /// 비행 중. 값은 진행도 0...1
        case flying(u: Double)
        /// 도착 뒤. 값은 흡수 진행도 0...1
        case absorbing(p: Double)
    }

    private struct Geometry {
        let start: CGPoint
        let target: CGPoint
        let control: CGPoint
        let startSize: CGFloat
        let targetSize: CGFloat
    }

    private func phase(of index: Int, now: Date) -> Phase {
        let gather = reduceMotion ? RewardFlightMath.Reduced.gather : RewardFlightMath.gather
        guard let departDate else {
            return .hold(gather: RevealMath.clamp(now.timeIntervalSince(launchDate) / gather))
        }
        let flightTime = reduceMotion ? RewardFlightMath.Reduced.flight : RewardFlightMath.flight
        let absorb = reduceMotion ? RewardFlightMath.Reduced.absorb : RewardFlightMath.absorb
        let stagger = reduceMotion ? 0.12 : RewardFlightMath.stagger
        let t = now.timeIntervalSince(departDate)
        let u = (t - RewardFlightMath.departTime(index, stagger: stagger)) / flightTime
        if u < 0 { return .hold(gather: 1) }
        if u <= 1 { return .flying(u: u) }
        return .absorbing(p: RevealMath.clamp((u - 1) * flightTime / absorb))
    }

    private func geometry(_ flight: RewardFlightCenter.Flight, index: Int, overlayOrigin: CGPoint) -> Geometry? {
        guard let slot = center.slotCenter(flight.slots.lowerBound + index) else { return nil }
        let start = CGPoint(x: flight.origin.x - overlayOrigin.x, y: flight.origin.y - overlayOrigin.y)
        let target = CGPoint(x: slot.x - overlayOrigin.x, y: slot.y - overlayOrigin.y)
        return Geometry(
            start: start,
            target: target,
            control: RewardFlightMath.control(from: start, to: target, index: index),
            startSize: flight.size,
            targetSize: max(center.slotDiameter * 1.15, 10)
        )
    }

    private func position(_ g: Geometry, s: Double) -> CGPoint {
        if reduceMotion {
            return CGPoint(x: RevealMath.lerp(g.start.x, g.target.x, s), y: RevealMath.lerp(g.start.y, g.target.y, s))
        }
        return RewardFlightMath.bezier(g.start, g.control, g.target, s)
    }

    private func diameter(_ g: Geometry, s: Double) -> CGFloat {
        CGFloat(RevealMath.lerp(Double(g.startSize), Double(g.targetSize), pow(s, 0.7)))
    }

    private func scene(
        _ flight: RewardFlightCenter.Flight, now: Date, overlayOrigin: CGPoint, size: CGSize
    ) -> some View {
        let items: [(index: Int, geometry: Geometry, phase: Phase)] = (0..<flight.count).compactMap { index in
            guard let g = geometry(flight, index: index, overlayOrigin: overlayOrigin) else {
                // 트리 위치를 아직 모르면 출발점에서 기다린다.
                let start = CGPoint(x: flight.origin.x - overlayOrigin.x, y: flight.origin.y - overlayOrigin.y)
                let g = Geometry(start: start, target: start, control: start, startSize: flight.size, targetSize: flight.size)
                return (index, g, .hold(gather: phaseGather(now)))
            }
            return (index, g, phase(of: index, now: now))
        }

        return ZStack {
            treeGlow(flight, items: items, overlayOrigin: overlayOrigin)

            // 가장 늦게 출발하는 장식이 아래, 먼저 나는 장식이 위
            ForEach(items.reversed(), id: \.index) { item in
                ornament(flight, item: item, now: now)
            }

            if !reduceMotion {
                Canvas { context, _ in
                    for item in items { drawEffects(&context, flight: flight, item: item) }
                }
                .allowsHitTesting(false)

                ForEach(items, id: \.index) { item in
                    flare(flight, item: item)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func phaseGather(_ now: Date) -> Double {
        let gather = reduceMotion ? RewardFlightMath.Reduced.gather : RewardFlightMath.gather
        return RevealMath.clamp(now.timeIntervalSince(launchDate) / gather)
    }

    // MARK: - 장식

    @ViewBuilder
    private func ornament(
        _ flight: RewardFlightCenter.Flight,
        item: (index: Int, geometry: Geometry, phase: Phase),
        now: Date
    ) -> some View {
        let g = item.geometry
        switch item.phase {
        case .hold(let gather):
            // 제자리에서 빛이 모인다. 살짝 떨리며 부푼다.
            let time = now.timeIntervalSinceReferenceDate
            let shake = reduceMotion ? 0 : gather * 2.2
            ZStack {
                if !reduceMotion, gather > 0.02 {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.glowCore.opacity(0.85 * gather), flight.style.tint.opacity(0.45 * gather), .clear],
                            center: .center, startRadius: 0, endRadius: g.startSize * 0.95
                        ))
                        .frame(width: g.startSize * 2, height: g.startSize * 2)
                        .blendMode(.plusLighter)
                }
                OrnamentView(style: flight.style, radiance: 1, heat: gather * 0.22, glint: -1, size: g.startSize)
                    .scaleEffect(1 + 0.1 * gather)
                    .offset(x: sin(time * 83) * shake, y: cos(time * 71) * shake)
            }
            .position(g.start)

        case .flying(let u):
            let s = RewardFlightMath.travel(u)
            let point = position(g, s: s)
            let d = diameter(g, s: s)
            let spin = reduceMotion ? 0 : s * 540 * (item.index % 2 == 0 ? 1 : -1)
            let fade = reduceMotion ? 1 - RevealMath.smooth((u - 0.6) / 0.4) * 0.6 : 1
            OrnamentView(style: flight.style, radiance: 1, heat: 0.12, glint: (u * 2).truncatingRemainder(dividingBy: 1), size: d)
                .rotationEffect(.degrees(spin))
                .opacity(fade)
                .position(point)

        case .absorbing(let p):
            let d = g.targetSize
            if reduceMotion {
                OrnamentView(style: flight.style, radiance: 1, size: d)
                    .opacity(1 - RevealMath.smooth(p / 0.8))
                    .position(g.target)
            } else if p < 0.55 {
                // 닿는 순간 커지며 하얗게 달아올랐다가 칸으로 스며든다.
                let pop = RevealMath.smooth(p / 0.14)
                let sink = RevealMath.smooth((p - 0.16) / 0.34)
                let scale = RevealMath.lerp(1, 1.9, pop) * RevealMath.lerp(1, 0.35, sink)
                OrnamentView(style: flight.style, radiance: 1, heat: max(1 - p / 0.3, 0), glint: -1, size: d)
                    .scaleEffect(scale)
                    .opacity(1 - RevealMath.smooth((p - 0.3) / 0.25))
                    .position(g.target)
            }
        }
    }

    // MARK: - 트리 전체의 은은한 후광

    /// 장식이 칸에 박히는 순간 트리 전체에 아주 약하고 작게 번졌다 사라지는 따뜻한 빛.
    /// 장식 하나가 박힐 때마다 한 번씩 겹쳐 오르며, 세기는 일부러 낮게 둔다.
    @ViewBuilder
    private func treeGlow(
        _ flight: RewardFlightCenter.Flight,
        items: [(index: Int, geometry: Geometry, phase: Phase)],
        overlayOrigin: CGPoint
    ) -> some View {
        let strength = items.reduce(0.0) { total, item in
            guard case .absorbing(let p) = item.phase else { return total }
            // 닿은 직후 빠르게 올라 천천히 가라앉는다.
            return total + RevealMath.smooth(p / 0.1) * exp(-max(p - 0.1, 0) * 4.5)
        }
        if !reduceMotion, strength > 0.003, center.hasTreeFrame {
            let frame = center.treeSceneFrame
            let alpha = min(strength, 1.4) * 0.15
            RadialGradient(
                colors: [
                    Color.glowCore.opacity(alpha),
                    flight.style.tint.opacity(alpha * 0.45),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: frame.width * 0.62
            )
            .frame(width: frame.width * 1.3, height: frame.height * 1.3)
            .blendMode(.plusLighter)
            .position(x: frame.midX - overlayOrigin.x, y: frame.midY - overlayOrigin.y)
        }
    }

    // MARK: - 셰이더 섬광

    @ViewBuilder
    private func flare(
        _ flight: RewardFlightCenter.Flight,
        item: (index: Int, geometry: Geometry, phase: Phase)
    ) -> some View {
        if case .absorbing(let p) = item.phase, p < 1 {
            let radius = max(item.geometry.targetSize * 3.2, 34)
            let side = radius * 2.6
            Rectangle()
                .fill(Color.glowWhite)
                .frame(width: side, height: side)
                .colorEffect(ShaderLibrary.absorbFlare(
                    .float2(CGPoint(x: side / 2, y: side / 2)),
                    .float(p),
                    .float(radius),
                    .color(flight.style.tint),
                    .color(.glowCore)
                ))
                .blendMode(.plusLighter)
                .position(item.geometry.target)
        }
    }

    // MARK: - 꼬리빛과 입자

    private func drawEffects(
        _ context: inout GraphicsContext,
        flight: RewardFlightCenter.Flight,
        item: (index: Int, geometry: Geometry, phase: Phase)
    ) {
        let g = item.geometry
        context.blendMode = .plusLighter

        switch item.phase {
        case .hold:
            break

        case .flying(let u):
            let tint = flight.style.tint
            // 꼬리빛: 지나온 길을 따라 작아지고 흐려지는 빛 알갱이
            let steps = 22
            for k in 1...steps {
                let uk = u - Double(k) * 0.016
                if uk < 0 { break }
                let s = RewardFlightMath.travel(uk)
                let point = position(g, s: s)
                let fall = 1 - Double(k) / Double(steps + 1)
                let radius = diameter(g, s: s) * 0.2 * fall
                let alpha = pow(fall, 1.6)
                fill(&context, point, radius * 1.7, tint.opacity(0.16 * alpha))
                fill(&context, point, radius, Color.glowGold.opacity(0.7 * alpha))
                fill(&context, point, radius * 0.45, Color.glowCore.opacity(0.9 * alpha))
            }

            // 반짝임: 지나가는 길에 흩뿌려져 떨어지며 사라진다.
            let flightSeconds = RewardFlightMath.flight
            for j in 0..<18 {
                let born = 0.04 + 0.9 * RewardFlightMath.hash(j, item.index * 7 + 1)
                let age = (u - born) * flightSeconds
                let life = 0.55
                guard age > 0, age < life else { continue }
                let angle = RewardFlightMath.hash(j, item.index * 7 + 2) * 2 * .pi
                let speed = 30 + 70 * RewardFlightMath.hash(j, item.index * 7 + 3)
                let origin = position(g, s: RewardFlightMath.travel(born))
                let point = CGPoint(
                    x: origin.x + cos(angle) * speed * age,
                    y: origin.y + sin(angle) * speed * age + 80 * age * age
                )
                let fade = 1 - age / life
                let color = RevealParticles.palette[Int(RewardFlightMath.hash(j, item.index * 7 + 4) * 100) % RevealParticles.palette.count]
                sparkle(&context, point, size: (2.5 + 3 * RewardFlightMath.hash(j, item.index * 7 + 5)) * (0.4 + 0.6 * fade), color: color.opacity(fade))
            }

        case .absorbing(let p):
            // 도착한 자리에서 사방으로 퍼지는 반짝임
            let reach = max(g.targetSize * 2.6, 30)
            for j in 0..<20 {
                let jitter = RewardFlightMath.hash(j, item.index * 11 + 1)
                let angle = (Double(j) / 20) * 2 * .pi + jitter * 0.4
                let travel = RevealMath.easeOut(p) * reach * (0.45 + 0.7 * RewardFlightMath.hash(j, item.index * 11 + 2))
                let fade = pow(max(1 - p, 0), 1.3)
                let point = CGPoint(x: g.target.x + cos(angle) * travel, y: g.target.y + sin(angle) * travel + 14 * p * p)
                let color = RevealParticles.palette[j % RevealParticles.palette.count]
                sparkle(&context, point, size: (2 + 3.5 * jitter) * (0.3 + 0.7 * fade), color: color.opacity(fade))
            }
        }
    }

    private func fill(_ context: inout GraphicsContext, _ point: CGPoint, _ radius: CGFloat, _ color: Color) {
        guard radius > 0.1 else { return }
        context.fill(
            Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(color)
        )
    }

    /// 네 갈래 별 모양 반짝이
    private func sparkle(_ context: inout GraphicsContext, _ point: CGPoint, size: CGFloat, color: Color) {
        guard size > 0.2 else { return }
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y - size * 1.9))
        path.addQuadCurve(to: CGPoint(x: point.x + size * 1.9, y: point.y), control: point)
        path.addQuadCurve(to: CGPoint(x: point.x, y: point.y + size * 1.9), control: point)
        path.addQuadCurve(to: CGPoint(x: point.x - size * 1.9, y: point.y), control: point)
        path.addQuadCurve(to: CGPoint(x: point.x, y: point.y - size * 1.9), control: point)
        context.fill(path, with: .color(color))
        fill(&context, point, size * 0.5, Color.glowCore.opacity(0.9))
    }
}
