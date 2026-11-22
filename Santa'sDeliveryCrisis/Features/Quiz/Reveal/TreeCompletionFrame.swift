import SwiftUI

/// D1 완성 연출의 시간표와 좌표. 저장된 트리나 보상을 변경하지 않는다.
struct TreeCompletionFrame {
    /// 마지막 장식부터 배달 출발까지의 전체 길이.
    static let duration: TimeInterval = 10
    /// 출발 인사를 시작하는 시각.
    static let greetingAt: TimeInterval = 2
    /// 마을 장면으로 전환하기 시작하는 시각.
    static let villageAt: TimeInterval = 3.2
    /// 썰매 비행의 시작과 종료 시각.
    static let flightRange: ClosedRange<TimeInterval> = 4.4...8.6
    /// 배달 출발 문구를 표시하는 시각.
    static let captionAt: TimeInterval = 8.8

    /// 현재까지 실제로 재생한 시간.
    let time: TimeInterval
    /// 현재 장면의 표시 영역.
    let size: CGSize
    /// 동작 줄이기에서는 썰매와 마을을 정지 상태로 표시한다.
    let reduced: Bool

    /// 작업실은 원본 정사각형 비율로 화면 중앙에 표시한다.
    var roomSide: CGFloat { min(size.width, size.height * 0.75) }
    /// 작업실 그림의 왼쪽 위 위치.
    var roomOrigin: CGPoint {
        CGPoint(x: (size.width - roomSide) / 2, y: (size.height - roomSide) / 2 - size.height * 0.05)
    }
    /// 작업실 이미지에 그려진 꼭대기 별의 중심.
    var star: CGPoint { CGPoint(x: roomSide * 0.61, y: roomSide * 0.045) }
    /// 마을로 넘어가는 부드러운 전환 정도.
    var villageOpacity: Double { reduced ? 1 : RevealMath.smooth((time - Self.villageAt) / 1) }
    /// 산타가 인사하는 동안만 말풍선을 보여 준다.
    var speechOpacity: Double {
        RevealMath.smooth((time - Self.greetingAt) / 0.3) * (1 - villageOpacity)
    }
    /// 꼭대기 별로 빛이 모이는 정도.
    var starLight: Double { RevealMath.smooth((time - 1.3) / 0.7) }
    /// 비행 구간 안의 진행률.
    var flightProgress: Double {
        RevealMath.clamp((time - Self.flightRange.lowerBound) / (Self.flightRange.upperBound - Self.flightRange.lowerBound))
    }
    /// 시안과 동일하게 왼쪽에서 오른쪽으로 완만하게 상승하는 썰매 중심.
    var sleighCenter: CGPoint {
        if reduced { return CGPoint(x: size.width * 0.53, y: size.height * 0.29) }
        return flightPoint(flightProgress)
    }
    /// 화면 밖에서 들어오고 나갈 때 썰매를 부드럽게 표시한다.
    var sleighOpacity: Double {
        if reduced { return 1 }
        guard Self.flightRange.contains(time) else { return 0 }
        return RevealMath.smooth(flightProgress / 0.08) * (1 - RevealMath.smooth((flightProgress - 0.94) / 0.06))
    }
    /// 출발 문구의 표시 정도.
    var captionOpacity: Double { reduced ? 1 : RevealMath.smooth((time - Self.captionAt) / 0.5) }

    /// 별빛 자취도 썰매와 같은 궤적을 사용한다.
    func flightPoint(_ progress: Double) -> CGPoint {
        CGPoint(
            x: size.width * (-0.38 + 1.76 * progress),
            y: size.height * (0.31 - 0.1 * progress + 0.016 * sin(progress * .pi * 2))
        )
    }
}
