import CoreGraphics

/// 공통 트리의 장식 위치와 표시 개수 보정을 관리한다.
enum TreeSlots {
    /// 모델이 정의한 트리 한 그루의 장식 칸 수.
    static let count = TreeRecord.slotCount

    /// 트리 이미지와 장식 배치가 공유하는 기준 좌표계. 이미지 파일의 픽셀 크기와는 다르다.
    static let designSize = CGSize(width: 220, height: 214)

    /// 트리 영역의 너비와 높이 비율.
    static let aspectRatio = designSize.width / designSize.height

    /// 주어진 영역 안에 기준 좌표계가 들어가는 최대 배율을 반환한다.
    /// - Parameter availableSize: 부모 뷰가 제공하는 영역.
    /// - Returns: 가로와 세로가 모두 영역 안에 들어가는 배율.
    static func scale(in availableSize: CGSize) -> CGFloat {
        min(availableSize.width / designSize.width, availableSize.height / designSize.height)
    }

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
    /// - Parameter filledCount: 저장된 장식 수.
    /// - Returns: 0부터 트리 한 그루의 최대 칸 수 사이의 값.
    static func clampedCount(_ filledCount: Int) -> Int {
        min(max(filledCount, 0), count)
    }
}
