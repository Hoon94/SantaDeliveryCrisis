import Foundation

/// 연출 계산에 쓰는 작은 수학 도구
enum RevealMath {
    /// 0...1로 자른다.
    static func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }

    /// 부드러운 계단(smoothstep). 0에서 1로 느리게 시작해 느리게 끝난다.
    static func smooth(_ x: Double) -> Double {
        let c = clamp(x)
        return c * c * (3 - 2 * c)
    }

    /// 빠르게 시작해 느리게 멈추는 곡선
    static func easeOut(_ x: Double) -> Double {
        let c = clamp(x)
        return 1 - pow(1 - c, 3)
    }

    /// 용수철 응답. 0에서 시작해 1을 지나쳤다가 1로 가라앉는다. `u`는 시작 뒤 흐른 시간(초), 음수면 0.
    /// 감쇠 7, 진동 9 rad/s인 부족감쇠(진동하며 줄어드는) 용수철의 해석해다.
    static func spring(_ u: Double, damping: Double = 7, frequency: Double = 9) -> Double {
        guard u > 0 else { return 0 }
        let decay = exp(-damping * u)
        return 1 - decay * (cos(frequency * u) + damping / frequency * sin(frequency * u))
    }

    /// `a`에서 `b`로 `t`만큼 섞는다.
    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
}
