/// 작업실의 장식 안내 문구를 만드는 순수 함수 모음.
enum TaskHomeCopy {
    /// 채워진 칸을 보정해 첫 실행 안내 또는 남은 장식 안내를 만든다.
    /// - Parameter filledCount: 저장된 장식 수. 0부터 최대 칸 수 사이로 보정한다.
    /// - Returns: 화면과 VoiceOver가 함께 사용하는 장식 진행 안내.
    static func remainingText(filledCount: Int) -> String {
        let count = TreeSlots.clampedCount(filledCount)
        guard count > 0 else { return "첫 장식을 얻어 트리를 꾸며 보세요" }
        return "트리를 완성하려면 장식 \(TreeSlots.count - count)개가 남았어요"
    }
}
