import SwiftUI

/// 장식 획득 연출의 한 시점. 시간 `t`와 화면 크기만 주면 그 순간의 모든 값(위치, 크기, 밝기, 흔들림)을 계산한다.
/// 상태를 쌓지 않으므로 같은 `t`는 항상 같은 장면이고, 느리게 돌려 보거나 특정 순간만 그려 볼 수 있다.
///
/// 흐름: 평범한 장식 등장 → 떨리며 빛이 모임 → 번쩍(충격파, 흔들림) → 조각이 퍼펑 튀고 후광 → 제목 → 위로 올라가며 결과 카드.
struct RevealFrame {
    // MARK: - 시간표(초)

    /// 평범한 장식이 나타나는 데 걸리는 시간
    static let plainIn = 0.55
    /// 빛 모으기 시작
    static let chargeStart = 0.7
    /// 번쩍임(충격) 순간
    static let impact = chargeStart + FeedbackCue.chargeUpDuration
    /// 번쩍임 뒤 제목이 나오기까지
    static let titleDelay = 0.55
    /// 장식이 위로 올라가고 결과 카드가 나오는 시각
    static let dockAt = impact + 2.2
    /// 결과 카드 등장 시각. 장식이 올라가기 시작하고 잠시 뒤
    static let cardAt = dockAt + 0.12

    /// 모션 줄이기가 켜졌을 때의 시간표
    enum Reduced {
        static let swapAt = 1.0
        static let dockAt = 2.4
        static let cardAt = dockAt + 0.2
    }

    // MARK: - 입력

    let t: Double
    let size: CGSize
    let reduced: Bool

    // MARK: - 파생 값

    /// 번쩍임 이후 시간. 번쩍이기 전에는 음수
    var impactT: Double { t - Self.impact }
    /// 충전 진행도 0...1
    var chargeProgress: Double { reduced ? 0 : RevealMath.clamp((t - Self.chargeStart) / FeedbackCue.chargeUpDuration) }
    /// 화면 짧은 변
    var minSide: CGFloat { min(size.width, size.height) }

    /// 장식 지름. 올라가면 줄어든다.
    var ornamentSize: CGFloat {
        let base = min(minSide * 0.44, 200)
        return base * (1 - 0.4 * dock)
    }

    /// 0(가운데)에서 1(위쪽에 자리 잡음)로 가는 값. 용수철이라 1을 살짝 넘었다 돌아온다.
    var dock: Double {
        if reduced { return RevealMath.smooth((t - Reduced.dockAt) / 0.6) }
        return RevealMath.spring(t - Self.dockAt, damping: 6.5, frequency: 8)
    }

    /// 장식 중심. 가운데보다 약간 위에서 시작해 위쪽으로 올라간다.
    var center: CGPoint {
        let start = CGPoint(x: size.width / 2, y: size.height * 0.45)
        let docked = CGPoint(x: size.width / 2, y: size.height * 0.21 + 14)
        let float = reduced ? 0 : sin(t * 1.7) * 5 * RevealMath.smooth((impactT - 0.8) / 0.6)
        return CGPoint(
            x: RevealMath.lerp(start.x, docked.x, dock),
            y: RevealMath.lerp(start.y, docked.y, dock) + float
        )
    }

    /// 지금 장식이 빛나는 상태인가(번쩍인 뒤)
    var radiance: Double {
        if reduced { return RevealMath.smooth((t - Reduced.swapAt) / 0.6) }
        return impactT >= 0 ? 1 : 0
    }

    /// 달아오른 정도
    var heat: Double {
        if reduced { return RevealMath.smooth((t - 0.5) / 0.5) * (1 - RevealMath.smooth((t - Reduced.swapAt) / 0.6)) * 0.7 }
        return pow(chargeProgress, 1.5) * (impactT >= 0 ? 0 : 1)
    }

    /// 장식 크기 배율. 등장, 충전 중 부풂, 번쩍인 뒤 튀어 오름
    var ornamentScale: Double {
        let appear = 0.55 + 0.45 * RevealMath.easeOut(t / Self.plainIn)
        if reduced { return appear }
        if impactT < 0 {
            return appear * (1 + 0.2 * pow(chargeProgress, 2.4))
        }
        // 번쩍인 직후 작게 시작해 1을 넘었다가 가라앉는다.
        return 1 - 0.7 * exp(-4.5 * impactT) * cos(10 * impactT)
    }

    /// 장식 전체의 투명도(등장 페이드)
    var ornamentOpacity: Double { RevealMath.smooth(t / Self.plainIn) }

    /// 충전 중 떨림. 점점 커진다.
    var jitter: (offset: CGSize, degrees: Double) {
        guard !reduced, chargeProgress > 0, impactT < 0 else { return (.zero, 0) }
        let amplitude = 0.8 + 9 * pow(chargeProgress, 2.2)
        let x = (sin(t * 91) + 0.6 * sin(t * 47 + 1.3)) * amplitude * 0.5
        let y = (cos(t * 83) + 0.6 * sin(t * 53 + 0.7)) * amplitude * 0.5
        return (CGSize(width: x, height: y), sin(t * 71) * amplitude * 0.22)
    }

    /// 광택이 훑고 지나가는 위치 0...1. 쉬는 동안은 -1
    var glint: Double {
        let g = reduced ? t - (Reduced.swapAt + 0.4) : impactT - 0.45
        guard g >= 0 else { return -1 }
        let phase = g.truncatingRemainder(dividingBy: 2.8)
        return phase < 1 ? phase : -1
    }

    // MARK: - 빛, 번쩍임, 충격

    /// 뒤쪽 어두운 막
    var scrimAlpha: Double { RevealMath.smooth(t / 0.5) * 0.88 }

    /// 후광 빛줄기 세기
    var raysIntensity: Double {
        if reduced { return RevealMath.smooth((t - Reduced.swapAt) / 0.8) * 0.6 }
        if impactT < 0 { return 0.22 * pow(chargeProgress, 2) }
        return RevealMath.smooth(impactT / 0.5) * (0.92 + 0.08 * sin(t * 2.2))
    }

    /// 중심 빛 덩어리의 크기, 맥동, 밝기
    var orb: (radius: CGFloat, pulse: Double, heat: Double, alpha: Double) {
        if reduced { return (minSide * 0.25, 0.5, heat, heat) }
        let p = chargeProgress
        let alpha = impactT < 0 ? RevealMath.smooth(p * 3) : exp(-impactT * 5)
        return (minSide * CGFloat(0.16 + 0.24 * p), 0.5 + 0.5 * sin(t * (6 + 20 * p)), pow(p, 1.4), alpha)
    }

    /// 화면 전체 번쩍임. 번쩍이기 직전에 하얗게 모였다가 터지며 사라진다.
    var flashAlpha: Double {
        if reduced { return 0 }
        let pre = impactT < 0 ? RevealMath.smooth((impactT + 0.2) / 0.2) * 0.9 : 0
        let post = impactT >= 0 ? exp(-impactT * 7.5) : 0
        return max(pre, post)
    }

    /// 충격파 파라미터. 번쩍인 뒤 잠시만 있다.
    var shock: (radius: Double, width: Double, amplitude: Double, aberration: Double)? {
        guard !reduced, impactT >= 0, impactT < 1.4 else { return nil }
        return (impactT * 1250, 130, 24 * exp(-impactT * 2.6), 8 * exp(-impactT * 3.2))
    }

    /// 번쩍인 직후 화면 흔들림
    var shake: CGSize {
        guard !reduced, impactT >= 0, impactT < 0.8 else { return .zero }
        let amplitude = 16 * exp(-impactT * 6.5)
        return CGSize(width: sin(impactT * 130) * amplitude, height: cos(impactT * 113 + 0.8) * amplitude * 0.7)
    }

    /// 장식 주변 반짝임 세기
    var twinkleStrength: Double {
        if reduced { return 0 }
        return RevealMath.smooth((impactT - 0.7) / 0.6)
    }

    // MARK: - 제목, 카드

    /// 제목이 나온 뒤 흐른 시간
    var titleT: Double {
        reduced ? t - (Reduced.swapAt + 0.3) : impactT - Self.titleDelay
    }

    /// 결과 카드가 나온 뒤 흐른 시간
    var cardT: Double { t - (reduced ? Reduced.cardAt : Self.cardAt) }

    /// 카드가 아래에서 올라오는 정도 0...1(용수철)
    var cardSlide: Double {
        if reduced { return RevealMath.smooth(cardT / 0.5) }
        return RevealMath.spring(cardT, damping: 7.5, frequency: 7)
    }
}
