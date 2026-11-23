import SwiftData

/// 트리 완성 흐름을 실제 마지막 스테이지로 확인하는 개발용 설정.
@MainActor
enum TreeCompletionConfiguration {
    #if DEBUG
    /// 앱 시작마다 마지막 스테이지만 남긴다. 일반 진행 확인 시 false로 되돌린다.
    static let startBeforeFinalStage = true
    #else
    static let startBeforeFinalStage = false
    #endif

    /// 기존 문제·풀이 기록은 유지하고 현재 트리의 보상 칸만 개발용으로 준비한다.
    static func prepare(in context: ModelContext) throws {
        #if DEBUG
        guard startBeforeFinalStage else { return }
        let tree = TreeManager(context: context).currentTree()
        tree.prepareBeforeFinalStage()
        try context.save()
        #endif
    }
}
