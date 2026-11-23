import Foundation
import SwiftData

/// 장식 지급과 트리 완성 처리.
///
/// 이 클래스는 값만 바꾸고 `save()`를 부르지 않는다.
/// 세션 완료, 장식 지급, 트리 갱신을 한 번에 저장하기 위해 저장은 `SessionManager.finish`가 한 번만 한다.
final class TreeManager: TreeManaging {
    private let context: ModelContext
    private let now: () -> Date

    /// - Parameters:
    ///   - context: 트리를 읽고 쓰는 ModelContext. `SessionManager`와 같은 것을 써야 한다.
    ///   - now: 현재 시각. 테스트에서 고정 값을 넘긴다.
    init(context: ModelContext, now: @escaping () -> Date = { Date() }) {
        self.context = context
        self.now = now
    }

    /// 현재 꾸미는 트리(`completedAt == nil`). 없으면 새로 만들어 넣는다(첫 실행).
    func currentTree() -> TreeRecord {
        if let existing = activeTrees().first {
            return existing
        }
        let tree = TreeRecord(startedAt: now())
        context.insert(tree)
        return tree
    }

    /// 아직 획득하지 않은 작업·난이도 칸을 채우고, 12칸을 모두 채우면 다음 트리를 만든다.
    func grant(task: WorkshopTask, difficulty: Difficulty) throws -> TreeGrantResult {
        let tree = currentTree()
        guard tree.recordReward(task: task, difficulty: difficulty) else {
            return TreeGrantResult(
                completedTree: nil, currentDecorationCount: tree.decorationCount, rewardOutcome: .alreadyEarned
            )
        }
        guard tree.decorationCount == TreeRecord.slotCount else {
            return TreeGrantResult(
                completedTree: nil, currentDecorationCount: tree.decorationCount, rewardOutcome: .earned
            )
        }
        tree.completedAt = now()
        context.insert(TreeRecord(startedAt: now()))
        return TreeGrantResult(completedTree: tree, currentDecorationCount: 0, rewardOutcome: .earned)
    }

    /// 완성된 트리 목록. 최근에 완성한 순서
    func completedTrees() -> [TreeRecord] {
        let all = (try? context.fetch(FetchDescriptor<TreeRecord>())) ?? []
        return all
            .filter { $0.completedAt != nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    // MARK: - 내부

    /// 꾸미는 중인 트리들. 정상이면 하나다. 여러 개면 가장 먼저 시작한 것을 쓴다.
    private func activeTrees() -> [TreeRecord] {
        let all = (try? context.fetch(FetchDescriptor<TreeRecord>())) ?? []
        return all
            .filter { $0.completedAt == nil }
            .sorted { $0.startedAt < $1.startedAt }
    }
}
