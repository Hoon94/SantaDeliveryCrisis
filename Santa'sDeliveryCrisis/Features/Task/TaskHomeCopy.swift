import Foundation

/// 작업실의 장식 안내 문구를 만드는 순수 함수 모음.
enum TaskHomeCopy {
    /// 채워진 칸을 보정해 첫 실행 안내 또는 남은 장식 안내를 만든다.
    static func remainingText(filledCount: Int) -> String {
        let count = TreeSlots.clampedCount(filledCount)
        guard count > 0 else { return "첫 장식을 얻어 트리를 꾸며 보세요" }
        return "트리를 완성하려면 장식 \(TreeSlots.count - count)개가 남았어요"
    }
}
