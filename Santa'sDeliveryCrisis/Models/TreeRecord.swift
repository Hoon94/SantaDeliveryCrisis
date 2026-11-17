import Foundation
import SwiftData

/// 트리 한 그루의 기록. `completedAt == nil`인 레코드가 현재 꾸미는 트리다.
@Model final class TreeRecord {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    /// nil이면 현재 꾸미는 중인 트리
    var completedAt: Date?
    /// 0...12
    var decorationCount: Int

    /// 트리 한 그루의 장식 칸 수
    static let slotCount = 12

    init(id: UUID = UUID(), startedAt: Date = Date(), completedAt: Date? = nil, decorationCount: Int = 0) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.decorationCount = decorationCount
    }
}
