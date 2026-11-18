import CoreGraphics

/// 공통 트리의 장식 위치와 표시 개수 보정을 관리한다.
enum TreeSlots {
    /// 모델이 정의한 트리 한 그루의 장식 칸 수.
    static let count = TreeRecord.slotCount

    /// 디자인 원본의 좌표계 크기.
    static let designSize = CGSize(width: 220, height: 214)

    /// 위에서 아래, 같은 줄에서는 왼쪽에서 오른쪽 순서인 장식 위치 비율.
    static let positions: [CGPoint] = [
        CGPoint(x: 110, y: 62),
        CGPoint(x: 98, y: 92),
        CGPoint(x: 122, y: 92),
        CGPoint(x: 88, y: 120),
        CGPoint(x: 110, y: 120),
        CGPoint(x: 132, y: 120),
        CGPoint(x: 80, y: 148),
        CGPoint(x: 110, y: 148),
        CGPoint(x: 140, y: 148),
        CGPoint(x: 70, y: 176),
        CGPoint(x: 110, y: 176),
        CGPoint(x: 150, y: 176)
    ].map { CGPoint(x: $0.x / designSize.width, y: $0.y / designSize.height) }

    /// 음수는 빈 트리로, 최대 칸 수를 넘는 값은 완성된 트리로 보정한다.
    static func clampedCount(_ n: Int) -> Int {
        min(max(n, 0), count)
    }
}
