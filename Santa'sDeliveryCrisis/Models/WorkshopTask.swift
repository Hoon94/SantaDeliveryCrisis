import Foundation

/// 보상을 쌓을 작업 장식. 출제할 문제 카테고리와는 독립적이다.
nonisolated enum WorkshopTask: String, Codable, CaseIterable, Sendable {
    case wishReception, giftProduction, wrapping, sleighLoading

    /// 화면과 접근성 설명에 표시하는 작업 이름.
    var displayName: String {
        switch self {
        case .wishReception: "소원 접수"
        case .giftProduction: "선물 생산"
        case .wrapping: "포장"
        case .sleighLoading: "썰매 적재"
        }
    }

    /// 저장된 보상 비트의 작업 순서. 표시 순서가 바뀌어도 이 값은 변경하지 않는다.
    private var rewardIndex: Int {
        switch self {
        case .wishReception: 0
        case .giftProduction: 1
        case .wrapping: 2
        case .sleighLoading: 3
        }
    }

    /// 작업마다 쉬움·보통·어려움 순서로 배정한 고정 보상 칸.
    func rewardBit(for difficulty: Difficulty) -> Int {
        let index: Int
        switch difficulty {
        case .easy: index = 0
        case .normal: index = 1
        case .hard: index = 2
        }
        return 1 << (rewardIndex * 3 + index)
    }
}

/// 세션 완료 시 확정해 저장하는 보상 결과. 기준 통과 여부와는 별개다.
nonisolated enum RewardOutcome: String, Codable, Sendable {
    case pending, earned, alreadyEarned, notEarned
}
