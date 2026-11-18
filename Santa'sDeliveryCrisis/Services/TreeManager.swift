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

    /// 장식을 지급한다. 12칸이 차면 완성 처리하고 빈 트리를 새로 시작한다.
    /// - Parameter decorations: 지급할 장식 수. 0이면 아무것도 바꾸지 않는다. 음수는 오류
    func grant(decorations: Int) throws -> TreeGrantResult {
        guard decorations >= 0 else { throw TreeError.negativeDecorations }

        var tree = currentTree()
        var completedTree: TreeRecord?

        // 한 개씩 쌓는다. 보상은 항상 1개라 이월은 생기지 않지만, 여러 개가 와도 안전하게 처리한다.
        for _ in 0..<decorations {
            tree.decorationCount += 1
            if tree.decorationCount >= TreeRecord.slotCount {
                tree.decorationCount = TreeRecord.slotCount
                tree.completedAt = now()
                completedTree = tree

                let next = TreeRecord(startedAt: now())
                context.insert(next)
                tree = next
            }
        }
        return TreeGrantResult(completedTree: completedTree, currentDecorationCount: tree.decorationCount)
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

/// 트리 처리 중 생기는 오류
enum TreeError: Error, LocalizedError {
    case negativeDecorations

    var errorDescription: String? {
        switch self {
        case .negativeDecorations: "장식 수는 0 이상이어야 합니다."
        }
    }
}
