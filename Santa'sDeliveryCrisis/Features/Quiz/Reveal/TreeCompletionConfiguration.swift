/// 트리 완성 연출의 개발용 확인 방식. 실제 보상과 트리 저장 조건은 바꾸지 않는다.
nonisolated enum TreeCompletionConfiguration {
    #if DEBUG
    /// 새 장식을 하나만 얻어도 완성 연출을 표시한다. 일반 동작 확인 시 false로 되돌린다.
    static let previewAfterOneReward = true
    #else
    /// 배포 빌드는 실제로 열두 칸을 채운 경우에만 완성 연출을 표시한다.
    static let previewAfterOneReward = false
    #endif
}
