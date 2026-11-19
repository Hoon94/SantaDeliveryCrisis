import SwiftUI

/// 장식 획득 연출의 입자들. 모든 입자는 "처음 값 + 시간"만으로 위치가 정해지는 식으로 그린다.
/// 그래서 프레임마다 상태를 저장할 필요가 없고, 어느 시각이든 바로 그 장면을 그릴 수 있다.
enum RevealParticles {
    // MARK: - 팔레트

    /// 입자 색. 트리 장식 색과 빛 색을 쓴다.
    static let palette: [Color] = [
        .ornamentRed, .ornamentGold, .ornamentBlue, .ornamentPink, .ornamentGreen, .ornamentOrange, .ornamentGold, .glowGold, .glowCore
    ]

    // MARK: - 입자 정의

    /// 충전 중에 장식으로 빨려 들어오는 빛 알갱이
    struct ChargeSpark {
        /// 시작 각도(라디안)
        let angle: Double
        /// 시작 거리를 화면 짧은 변에 대한 비율로
        let distance: Double
        /// 충전이 시작되고 몇 초 뒤에 나타나는가
        let delay: Double
        /// 날아오는 데 걸리는 시간
        let flight: Double
        /// 날아오는 동안 도는 정도(바퀴 수)
        let turns: Double
        let size: Double
        let colorIndex: Int
    }

    /// 번쩍인 뒤 사방으로 튀는 조각
    struct BurstPiece {
        enum Kind { case ball, star, ribbon, flake, spark }
        let kind: Kind
        /// 몇 번째 폭발에 속하는가(0: 퍼, 1: 펑)
        let wave: Int
        let angle: Double
        /// 처음 속도(포인트/초)
        let speed: Double
        let gravity: Double
        /// 공기 저항
        let drag: Double
        let life: Double
        let size: Double
        let spin: Double
        let spinRate: Double
        let colorIndex: Int
    }

    /// 장식 주변에서 반짝이는 별
    struct Twinkle {
        let angle: Double
        let distance: Double
        let phase: Double
        let rate: Double
        let size: Double
        let colorIndex: Int
    }

    // MARK: - 생성

    /// 충전 알갱이 목록
    static let chargeSparks: [ChargeSpark] = {
        var rng = SeededRandom(seed: 101)
        let duration = FeedbackCue.chargeUpDuration
        return (0..<110).map { i in
            // 뒤로 갈수록 더 자주 나타난다(앞쪽 0.3 구간에는 적게).
            let p = pow(rng.next(), 0.62)
            return ChargeSpark(
                angle: rng.next(in: 0...(2 * .pi)),
                distance: rng.next(in: 0.35...0.75),
                delay: p * (duration - 0.35),
                flight: rng.next(in: 0.7...1.25),
                turns: rng.next(in: 0.35...0.9) * (i % 2 == 0 ? 1 : -1),
                size: rng.next(in: 1.6...4.6),
                colorIndex: [1, 6, 7, 8, 7, 8, 3, 2][i % 8]
            )
        }
    }()

    /// 폭발 조각 목록
    static let burstPieces: [BurstPiece] = {
        var rng = SeededRandom(seed: 202)
        var pieces: [BurstPiece] = []
        func add(_ count: Int, wave: Int, kind: BurstPiece.Kind, speed: ClosedRange<Double>, size: ClosedRange<Double>, life: ClosedRange<Double>, gravity: Double, drag: Double) {
            for _ in 0..<count {
                pieces.append(BurstPiece(
                    kind: kind,
                    wave: wave,
                    angle: rng.next(in: 0...(2 * .pi)),
                    speed: rng.next(in: speed),
                    gravity: gravity,
                    drag: drag * rng.next(in: 0.8...1.25),
                    life: rng.next(in: life),
                    size: rng.next(in: size),
                    spin: rng.next(in: 0...(2 * .pi)),
                    spinRate: rng.next(in: -7...7),
                    colorIndex: Int(rng.next() * Double(palette.count)) % palette.count
                ))
            }
        }
        // 퍼: 작고 빠른 불꽃 위주
        add(26, wave: 0, kind: .spark, speed: 500...1100, size: 2...4, life: 0.5...0.9, gravity: 0, drag: 3.2)
        add(10, wave: 0, kind: .star, speed: 300...700, size: 9...15, life: 0.9...1.4, gravity: 160, drag: 2.0)
        // 펑: 장식과 리본, 눈송이가 크게 퍼진다.
        add(18, wave: 1, kind: .ball, speed: 420...980, size: 9...17, life: 1.6...2.4, gravity: 760, drag: 1.5)
        add(16, wave: 1, kind: .star, speed: 340...880, size: 12...22, life: 1.2...1.9, gravity: 220, drag: 1.7)
        add(46, wave: 1, kind: .ribbon, speed: 300...900, size: 5...8, life: 1.7...2.6, gravity: 520, drag: 2.2)
        add(18, wave: 1, kind: .flake, speed: 240...640, size: 8...15, life: 1.8...2.8, gravity: 140, drag: 1.9)
        add(34, wave: 1, kind: .spark, speed: 600...1400, size: 2...4.5, life: 0.5...1.1, gravity: 0, drag: 2.8)
        return pieces
    }()

    /// 장식 주변 반짝이
    static let twinkles: [Twinkle] = {
        var rng = SeededRandom(seed: 303)
        return (0..<16).map { i in
            Twinkle(
                angle: rng.next(in: 0...(2 * .pi)),
                distance: rng.next(in: 0.62...1.25),
                phase: rng.next(in: 0...(2 * .pi)),
                rate: rng.next(in: 1.4...3.2),
                size: rng.next(in: 6...15),
                colorIndex: [7, 8, 6, 7][i % 4]
            )
        }
    }()

    // MARK: - 그리기

    /// 충전: 빛 알갱이가 소용돌이치며 중심으로 빨려 들어오고, 조여 오는 고리가 맥동한다.
    /// - Parameters:
    ///   - t: 충전을 시작한 뒤 흐른 시간(초)
    ///   - center: 장식의 중심
    ///   - reach: 알갱이가 시작하는 거리의 기준(화면 짧은 변)
    static func drawCharge(_ context: inout GraphicsContext, t: Double, center: CGPoint, reach: CGFloat) {
        guard t > 0 else { return }
        let total = FeedbackCue.chargeUpDuration
        let progress = min(t / total, 1)

        context.drawLayer { layer in
            layer.blendMode = .plusLighter

            // 조여 오는 고리: 바깥에서 안으로 줄어들며 점점 밝아진다.
            for k in 0..<3 {
                let cycle = 0.85 - 0.3 * progress
                let phase = (t / cycle + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                let radius = reach * 0.5 * (1 - phase) + 26
                let alpha = pow(phase, 1.4) * (0.25 + 0.6 * progress)
                let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                layer.stroke(
                    Path(ellipseIn: rect),
                    with: .color(Color.glowGold.opacity(alpha)),
                    lineWidth: 1.2 + 2.2 * phase
                )
            }

            for spark in chargeSparks {
                let u = (t - spark.delay) / spark.flight
                guard u > 0, u < 1 else { continue }
                let start = point(of: spark, u: u, center: center, reach: reach)
                let brightness = min(u * 3.2, 1) * (u > 0.88 ? (1 - u) / 0.12 : 1)
                let color = palette[spark.colorIndex % palette.count]
                let size = spark.size * (1 + (1 - u) * 0.3)

                // 꼬리는 소용돌이 궤적을 따라 짧게 여러 조각으로 이어 그려서 곡선으로 보이게 한다.
                var trail = Path()
                trail.move(to: start)
                for step in 1...5 {
                    trail.addLine(to: point(of: spark, u: max(u - 0.014 * Double(step), 0), center: center, reach: reach))
                }
                layer.stroke(trail, with: .color(color.opacity(brightness * 0.5)), style: StrokeStyle(lineWidth: size * 0.7, lineCap: .round, lineJoin: .round))
                drawGlow(&layer, at: start, radius: size * 3.2, color: color, alpha: brightness * 0.5)
                layer.fill(
                    Path(ellipseIn: CGRect(x: start.x - size / 2, y: start.y - size / 2, width: size, height: size)),
                    with: .color(Color.glowCore.opacity(brightness))
                )
            }
        }
    }

    /// 알갱이의 위치. 소용돌이를 그리며 점점 빨라지게 안쪽으로 들어온다.
    private static func point(of spark: ChargeSpark, u: Double, center: CGPoint, reach: CGFloat) -> CGPoint {
        let radius = spark.distance * Double(reach) * pow(1 - u, 2.1)
        let angle = spark.angle + spark.turns * 2 * .pi * u
        return CGPoint(x: center.x + CGFloat(cos(angle) * radius), y: center.y + CGFloat(sin(angle) * radius))
    }

    /// 폭발: 번쩍인 뒤 조각이 사방으로 튄다.
    /// - Parameters:
    ///   - t: 번쩍인 뒤 흐른 시간(초)
    ///   - waveDelay: 펑(두 번째 폭발)이 퍼보다 늦는 시간
    static func drawBurst(_ context: inout GraphicsContext, t: Double, center: CGPoint, waveDelay: Double = 0.17) {
        guard t > 0 else { return }
        context.drawLayer { layer in
            for piece in burstPieces {
                let local = t - (piece.wave == 0 ? 0 : waveDelay)
                guard local > 0, local < piece.life else { continue }
                let position = burstPosition(piece, t: local, center: center)
                let fade = min(1, (piece.life - local) / (piece.life * 0.35))
                let color = palette[piece.colorIndex]
                let rotation = piece.spin + piece.spinRate * local

                switch piece.kind {
                case .spark:
                    layer.blendMode = .plusLighter
                    let tail = burstPosition(piece, t: max(local - 0.045, 0), center: center)
                    var line = Path()
                    line.move(to: tail)
                    line.addLine(to: position)
                    layer.stroke(line, with: .color(color.opacity(fade)), style: StrokeStyle(lineWidth: piece.size, lineCap: .round))
                    drawGlow(&layer, at: position, radius: piece.size * 4, color: color, alpha: fade * 0.6)
                case .star:
                    layer.blendMode = .plusLighter
                    drawGlow(&layer, at: position, radius: piece.size * 1.8, color: color, alpha: fade * 0.5)
                    layer.fill(star4(at: position, outer: piece.size, rotation: rotation), with: .color(Color.glowCore.opacity(fade)))
                    layer.fill(star4(at: position, outer: piece.size * 0.7, rotation: rotation + .pi / 4), with: .color(color.opacity(fade)))
                case .ball:
                    layer.blendMode = .normal
                    drawBall(&layer, at: position, radius: piece.size, color: color, alpha: fade, rotation: rotation)
                case .ribbon:
                    layer.blendMode = .normal
                    // 리본이 나풀거리며 뒤집히는 느낌: 폭을 코사인으로 줄였다 늘린다.
                    let flutter = cos(local * 11 + piece.spin)
                    var inner = layer
                    inner.translateBy(x: position.x, y: position.y)
                    inner.rotate(by: .radians(rotation))
                    inner.scaleBy(x: 1, y: CGFloat(max(abs(flutter), 0.12)))
                    let rect = CGRect(x: -piece.size * 1.8, y: -piece.size * 0.55, width: piece.size * 3.6, height: piece.size * 1.1)
                    inner.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(color.opacity(fade)))
                case .flake:
                    layer.blendMode = .plusLighter
                    drawSnowflake(&layer, at: position, radius: piece.size, rotation: rotation, alpha: fade * 0.95)
                }
            }
        }
    }

    /// 항력이 있는 중력 운동의 해석해. 시간만 알면 위치가 나온다.
    private static func burstPosition(_ piece: BurstPiece, t: Double, center: CGPoint) -> CGPoint {
        let k = piece.drag
        let decay = (1 - exp(-k * t)) / k
        let vx = cos(piece.angle) * piece.speed
        let vy = sin(piece.angle) * piece.speed
        let terminal = piece.gravity / k
        let x = vx * decay
        let y = (vy - terminal) * decay + terminal * t
        return CGPoint(x: center.x + CGFloat(x), y: center.y + CGFloat(y))
    }

    /// 장식 주변에서 깜빡이는 별. 장식이 자리 잡은 뒤 계속 그린다.
    static func drawTwinkles(_ context: inout GraphicsContext, t: Double, center: CGPoint, radius: CGFloat, strength: Double) {
        guard strength > 0 else { return }
        context.drawLayer { layer in
            layer.blendMode = .plusLighter
            for tw in twinkles {
                let pulse = max(0, sin(t * tw.rate + tw.phase))
                let a = pow(pulse, 3) * strength
                guard a > 0.02 else { continue }
                let r = radius * CGFloat(tw.distance)
                let p = CGPoint(x: center.x + cos(tw.angle) * r, y: center.y + sin(tw.angle) * r)
                let color = palette[tw.colorIndex % palette.count]
                drawGlow(&layer, at: p, radius: tw.size * 1.6, color: color, alpha: a * 0.5)
                layer.fill(star4(at: p, outer: tw.size * (0.5 + 0.5 * pulse), rotation: t * 0.4 + tw.phase), with: .color(Color.glowCore.opacity(a)))
            }
        }
    }

    /// 번쩍 순간에 퍼지는 후광 고리들
    static func drawHaloRings(_ context: inout GraphicsContext, t: Double, center: CGPoint, speed: CGFloat) {
        guard t > 0 else { return }
        context.drawLayer { layer in
            layer.blendMode = .plusLighter
            for k in 0..<3 {
                let local = t - Double(k) * 0.12
                guard local > 0, local < 1.1 else { continue }
                let u = local / 1.1
                let radius = CGFloat(1 - pow(1 - u, 2.4)) * speed * (0.62 + 0.28 * CGFloat(k))
                let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                let color: Color = k == 1 ? .glowCore : .glowGold
                layer.stroke(Path(ellipseIn: rect), with: .color(color.opacity((1 - u) * 0.8)), lineWidth: 10 * (1 - u) + 1)
            }
        }
    }

    // MARK: - 도형

    /// 퍼지는 빛 번짐
    static func drawGlow(_ context: inout GraphicsContext, at point: CGPoint, radius: CGFloat, color: Color, alpha: Double) {
        guard alpha > 0.01 else { return }
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [color.opacity(alpha), color.opacity(0)]),
                center: point, startRadius: 0, endRadius: radius
            )
        )
    }

    /// 네 갈래로 뾰족한 별
    static func star4(at center: CGPoint, outer: Double, rotation: Double) -> Path {
        var path = Path()
        let inner = outer * 0.2
        for i in 0..<8 {
            let radius = i % 2 == 0 ? outer : inner
            let angle = rotation + Double(i) * .pi / 4
            let p = CGPoint(x: center.x + CGFloat(cos(angle) * radius), y: center.y + CGFloat(sin(angle) * radius))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    /// 작은 장식 공: 둥근 몸통, 윗면 빛, 금속 뚜껑
    private static func drawBall(_ context: inout GraphicsContext, at point: CGPoint, radius: Double, color: Color, alpha: Double, rotation: Double) {
        let r = CGFloat(radius)
        let body = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.fill(
            Path(ellipseIn: body),
            with: .radialGradient(
                Gradient(colors: [Color.glowWhite.opacity(alpha), color.opacity(alpha), Color.inkShadow.opacity(alpha * 0.8)]),
                center: CGPoint(x: point.x - r * 0.35, y: point.y - r * 0.4), startRadius: 0, endRadius: r * 1.5
            )
        )
        let cap = CGRect(x: point.x - r * 0.28, y: point.y - r * 1.2, width: r * 0.56, height: r * 0.4)
        context.fill(Path(roundedRect: cap, cornerRadius: 1.5), with: .color(Color.decorationCap.opacity(alpha)))
    }

    /// 여섯 갈래 눈송이
    private static func drawSnowflake(_ context: inout GraphicsContext, at point: CGPoint, radius: Double, rotation: Double, alpha: Double) {
        var path = Path()
        for i in 0..<6 {
            let angle = rotation + Double(i) * .pi / 3
            let tip = CGPoint(x: point.x + CGFloat(cos(angle) * radius), y: point.y + CGFloat(sin(angle) * radius))
            path.move(to: point)
            path.addLine(to: tip)
            let mid = CGPoint(x: point.x + CGFloat(cos(angle) * radius * 0.6), y: point.y + CGFloat(sin(angle) * radius * 0.6))
            for side in [-1.0, 1.0] {
                let branch = angle + side * .pi / 4
                path.move(to: mid)
                path.addLine(to: CGPoint(x: mid.x + CGFloat(cos(branch) * radius * 0.32), y: mid.y + CGFloat(sin(branch) * radius * 0.32)))
            }
        }
        context.stroke(path, with: .color(Color.glowWhite.opacity(alpha)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }
}
