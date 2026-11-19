import CoreHaptics
import UIKit

/// 진동을 낸다. 단순한 조작은 UIKit 피드백 생성기를 쓰고, 연출은 `CoreHaptics`로 세기와 날카로움이 시간에 따라 변하는 패턴을 만든다.
/// 진동을 지원하지 않는 기기(아이패드, 시뮬레이터)에서는 아무 일도 하지 않는다.
final class HapticPlayer {
    private var engine: CHHapticEngine?
    private var chargePlayer: CHHapticAdvancedPatternPlayer?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private let selection = UISelectionFeedbackGenerator()
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    init() {}

    /// 엔진을 켠다. 여러 번 불러도 안전하다.
    func prepare() {
        guard supportsHaptics, engine == nil else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak self] in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated { try? self?.engine?.start() }
                }
            }
            try engine.start()
            self.engine = engine
        } catch {
            print("햅틱 엔진 시작 실패: \(error.localizedDescription)")
        }
    }

    /// 신호에 맞는 진동을 낸다.
    func play(_ cue: FeedbackCue) {
        switch cue {
        case .select:
            selection.selectionChanged()
        case .button, .next:
            lightImpact.impactOccurred(intensity: 0.7)
        case .confirm:
            mediumImpact.impactOccurred(intensity: 0.8)
        case .hint:
            lightImpact.impactOccurred(intensity: 0.5)
        case .correct:
            notification.notificationOccurred(.success)
        case .wrong:
            notification.notificationOccurred(.error)
        case .popup:
            lightImpact.impactOccurred(intensity: 0.6)
        case .chargeUp:
            playPattern(for: cue, keepAs: \.chargePlayer, fallback: { rigidImpact.impactOccurred(intensity: 0.4) })
        case .impact, .burst, .reveal, .treeComplete, .launch, .absorb:
            playPattern(for: cue, keepAs: nil, fallback: { rigidImpact.impactOccurred(intensity: cue == .launch ? 0.5 : 1.0) })
        }
    }

    /// 길게 이어지는 진동을 멈춘다.
    func stop(_ cue: FeedbackCue) {
        guard cue == .chargeUp, let player = chargePlayer else { return }
        try? player.stop(atTime: CHHapticTimeImmediate)
        chargePlayer = nil
    }

    // MARK: - 패턴

    private func playPattern(
        for cue: FeedbackCue,
        keepAs keyPath: ReferenceWritableKeyPath<HapticPlayer, CHHapticAdvancedPatternPlayer?>?,
        fallback: () -> Void
    ) {
        prepare()
        guard supportsHaptics, let engine, let pattern = Self.pattern(for: cue) else {
            fallback()
            return
        }
        do {
            let player = try engine.makeAdvancedPlayer(with: pattern)
            if let keyPath { self[keyPath: keyPath] = player }
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback()
        }
    }

    private static func transient(_ time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time
        )
    }

    private static func continuous(_ time: TimeInterval, duration: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time,
            duration: duration
        )
    }

    private static func pattern(for cue: FeedbackCue) -> CHHapticPattern? {
        var events: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []

        switch cue {
        case .chargeUp:
            // 약하게 떨리기 시작해서 점점 세지고 날카로워진다. 끝으로 갈수록 톡톡 치는 간격이 촘촘해진다.
            let d = FeedbackCue.chargeUpDuration
            events.append(continuous(0, duration: d, intensity: 1.0, sharpness: 0.5))
            var t = 0.0
            var gap = 0.3
            while t < d - 0.1 {
                let p = Float(t / d)
                events.append(transient(t, intensity: 0.25 + 0.7 * p, sharpness: 0.3 + 0.6 * p))
                t += gap
                gap = max(gap * 0.86, 0.045)
            }
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticIntensityControl, controlPoints: [
                    .init(relativeTime: 0, value: 0.08),
                    .init(relativeTime: d * 0.5, value: 0.28),
                    .init(relativeTime: d * 0.85, value: 0.7),
                    .init(relativeTime: d, value: 1.0)
                ], relativeTime: 0))
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl, controlPoints: [
                    .init(relativeTime: 0, value: 0.1),
                    .init(relativeTime: d, value: 0.95)
                ], relativeTime: 0))
        case .impact:
            events.append(transient(0, intensity: 1.0, sharpness: 1.0))
            events.append(continuous(0.02, duration: 0.45, intensity: 0.6, sharpness: 0.2))
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticIntensityControl, controlPoints: [
                    .init(relativeTime: 0, value: 1.0),
                    .init(relativeTime: 0.45, value: 0.0)
                ], relativeTime: 0))
        case .burst:
            events.append(transient(0, intensity: 0.7, sharpness: 0.7))
            events.append(transient(0.17, intensity: 1.0, sharpness: 0.9))
            events.append(continuous(0.2, duration: 0.5, intensity: 0.35, sharpness: 0.5))
            for k in 0..<8 {
                events.append(transient(0.3 + Double(k) * 0.09, intensity: 0.45 - Float(k) * 0.04, sharpness: 0.9))
            }
        case .reveal:
            // 올라가는 세 번의 톡, 이어서 부드러운 여운
            for (k, i) in [0.45, 0.65, 0.9].enumerated() {
                events.append(transient(Double(k) * 0.11, intensity: Float(i), sharpness: 0.8))
            }
            events.append(continuous(0.34, duration: 0.8, intensity: 0.3, sharpness: 0.3))
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticIntensityControl, controlPoints: [
                    .init(relativeTime: 0.34, value: 1.0),
                    .init(relativeTime: 1.14, value: 0.0)
                ], relativeTime: 0))
        case .launch:
            // 올라가며 점점 세지는 떨림. 끝에서 가장 날카롭다.
            let d = 0.75
            events.append(continuous(0, duration: d, intensity: 0.7, sharpness: 0.3))
            for k in 0..<5 {
                events.append(transient(0.08 + Double(k) * 0.13, intensity: 0.25 + Float(k) * 0.1, sharpness: 0.5 + Float(k) * 0.1))
            }
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticIntensityControl, controlPoints: [
                    .init(relativeTime: 0, value: 0.2),
                    .init(relativeTime: d, value: 0.9)
                ], relativeTime: 0))
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl, controlPoints: [
                    .init(relativeTime: 0, value: 0.2),
                    .init(relativeTime: d, value: 0.9)
                ], relativeTime: 0))
        case .absorb:
            // 쿵 하고 받은 뒤 부드럽게 스며든다.
            events.append(transient(0, intensity: 1.0, sharpness: 0.85))
            events.append(continuous(0.03, duration: 0.3, intensity: 0.45, sharpness: 0.2))
            for k in 0..<3 {
                events.append(transient(0.14 + Double(k) * 0.1, intensity: 0.4 - Float(k) * 0.1, sharpness: 0.9))
            }
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticIntensityControl, controlPoints: [
                    .init(relativeTime: 0.03, value: 1.0),
                    .init(relativeTime: 0.33, value: 0.0)
                ], relativeTime: 0))
        case .treeComplete:
            for k in 0..<7 {
                events.append(transient(Double(k) * 0.1, intensity: 0.4 + Float(k) * 0.08, sharpness: 0.8))
            }
            events.append(transient(0.85, intensity: 1.0, sharpness: 1.0))
            events.append(continuous(0.87, duration: 1.2, intensity: 0.5, sharpness: 0.3))
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticIntensityControl, controlPoints: [
                    .init(relativeTime: 0.87, value: 1.0),
                    .init(relativeTime: 2.07, value: 0.0)
                ], relativeTime: 0))
        default:
            return nil
        }
        return try? CHHapticPattern(events: events, parameterCurves: curves)
    }
}
