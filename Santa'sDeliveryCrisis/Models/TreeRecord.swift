import Foundation
import SwiftData

/// 트리 한 그루의 기록. `completedAt == nil`인 레코드가 현재 꾸미는 트리다.
@Model final class TreeRecord {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    /// nil이면 현재 꾸미는 중인 트리
    var completedAt: Date?
    /// 작업별 쉬움·보통·어려움 순서의 12칸 획득 상태. 개수와 별도로 중복 집계하지 않는다.
    private(set) var rewardMask: Int = 0

    /// 획득한 서로 다른 작업·난이도 조합의 수(0...12).
    var decorationCount: Int { rewardMask.nonzeroBitCount }

    /// 트리 한 그루의 장식 칸 수
    static let slotCount = 12

    init(id: UUID = UUID(), startedAt: Date = Date(), completedAt: Date? = nil, decorationCount: Int = 0) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        // 개수를 받는 초기화는 프리뷰 샘플용이다. 실제 보상은 recordReward로 해당 칸을 채운다.
        self.rewardMask = (1 << min(max(decorationCount, 0), Self.slotCount)) - 1
    }

    /// 현재 트리에서 이 작업·난이도의 장식을 이미 얻었는지 확인한다.
    func hasReward(task: WorkshopTask, difficulty: Difficulty) -> Bool {
        rewardMask & task.rewardBit(for: difficulty) != 0
    }

    /// 해당 칸을 채운다. 이미 획득한 칸이면 변경하지 않고 false를 반환한다.
    @discardableResult
    func recordReward(task: WorkshopTask, difficulty: Difficulty) -> Bool {
        guard !hasReward(task: task, difficulty: difficulty) else { return false }
        rewardMask |= task.rewardBit(for: difficulty)
        return true
    }

    #if DEBUG
    /// 지도 순서의 마지막 스테이지를 제외한 열한 칸을 채운다.
    func prepareBeforeFinalStage() {
        rewardMask = QuizStage.all.dropLast().reduce(0) {
            $0 | $1.task.rewardBit(for: $1.difficulty)
        }
    }
    #endif

}
