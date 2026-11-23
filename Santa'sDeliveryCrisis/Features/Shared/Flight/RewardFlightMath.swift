import CoreGraphics
import Foundation

/// 장식 비행의 시간표와 경로 계산. 모두 시간 `t`만 받는 순수한 함수라서 어느 순간이든 같은 장면을 그린다.
///
/// 한 장식의 흐름: 모으기(출발 전, 제자리에서 빛이 모임) → 비행(곡선을 그리며 가속) → 도착 흡수(번쩍임, 칸에 스며듦).
/// 장식이 여러 개면 `stagger`초 간격으로 차례로 출발한다.
enum RewardFlightMath {
    /// 출발 전에 제자리에서 빛을 모으는 시간(초)
    static let gather = 0.38
    /// 출발해서 도착까지 걸리는 시간(초)
    static let flight = 0.78
    /// 장식 사이의 출발 간격(초)
    static let stagger = 0.24
    /// 도착한 뒤 번쩍임이 이어지는 시간(초)
    static let absorb = 0.8
    /// 도착 순간에서 칸이 채워져 보이기까지(초)
    static let fillDelay = 0.06

    /// 모션 줄이기가 켜졌을 때: 모으기, 이동, 흡수 시간
    enum Reduced {
        static let gather = 0.2
        static let flight = 0.5
        static let absorb = 0.4
    }

    /// 출발 시각 기준(출발 신호 뒤)으로 `index`번째 장식이 떠나는 시각
    static func departTime(_ index: Int, stagger: Double = Self.stagger) -> Double {
        Double(index) * stagger
    }

    /// `index`번째 장식이 칸에 닿는 시각
    static func landTime(_ index: Int, flight: Double = Self.flight, stagger: Double = Self.stagger) -> Double {
        departTime(index, stagger: stagger) + flight
    }

    /// 모든 장식이 도착하고 연출이 끝나는 시각
    static func totalDuration(count: Int, reduced: Bool) -> Double {
        let f = reduced ? Reduced.flight : flight
        let a = reduced ? Reduced.absorb : absorb
        return landTime(max(count - 1, 0), flight: f, stagger: reduced ? 0.12 : stagger) + a
    }

    /// 비행 진행도 0...1을 이동 거리 비율로 바꾼다. 천천히 출발해 점점 빨라지고 닿는 순간 가장 빠르다("슝").
    static func travel(_ u: Double) -> Double {
        let c = min(max(u, 0), 1)
        let smooth = c * c * (3 - 2 * c)
        return 0.7 * pow(c, 2.3) + 0.3 * smooth
    }

    /// 2차 베지에 곡선 위의 점
    static func bezier(_ a: CGPoint, _ control: CGPoint, _ b: CGPoint, _ s: Double) -> CGPoint {
        let u = 1 - s
        return CGPoint(
            x: u * u * a.x + 2 * u * s * control.x + s * s * b.x,
            y: u * u * a.y + 2 * u * s * control.y + s * s * b.y
        )
    }

    /// 출발점과 도착점 사이를 휘어 가는 경로의 제어점.
    /// 장식마다 좌우를 번갈아 휘어서 여러 개가 같은 길로 겹치지 않는다.
    /// - Parameters:
    ///   - index: 몇 번째 장식인지. 짝수는 오른쪽, 홀수는 왼쪽으로 휜다.
    static func control(from a: CGPoint, to b: CGPoint, index: Int) -> CGPoint {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let distance = max(hypot(dx, dy), 1)
        // 진행 방향에 수직인 단위 벡터
        let nx = -dy / distance
        let ny = dx / distance
        let side: Double = index % 2 == 0 ? 1 : -1
        let bend = distance * (0.38 + 0.08 * Double(index / 2))
        return CGPoint(
            x: (a.x + b.x) / 2 + nx * bend * side,
            y: (a.y + b.y) / 2 + ny * bend * side - distance * 0.12
        )
    }

    /// 위치가 시간에 따라 변해도 입자 모양이 매번 같도록 하는 0...1 해시
    static func hash(_ a: Int, _ b: Int = 0) -> Double {
        var x = UInt64(bitPattern: Int64(a &* 73_856_093 ^ b &* 19_349_663)) &* 0x9E37_79B9_7F4A_7C15
        x ^= x >> 29
        x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 32
        return Double(x % 100_000) / 100_000
    }
}
