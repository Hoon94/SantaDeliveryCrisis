import Foundation

/// 기존 작업·난이도 보상 칸을 저장 형식 변경 없이 정렬하는 출제 스테이지.
nonisolated struct QuizStage: Identifiable, Hashable, Sendable {
    /// 보상을 저장하는 기존 작업 식별자.
    let task: WorkshopTask
    /// 이 단계에서 출제할 난이도.
    let difficulty: Difficulty

    /// 난이도별 네 단계, 총 열두 단계를 고정된 순서로 배치한다.
    static let all: [QuizStage] = [Difficulty.easy, .normal, .hard].flatMap { difficulty in
        [WorkshopTask.wishReception, .giftProduction, .wrapping, .sleighLoading].map {
            QuizStage(task: $0, difficulty: difficulty)
        }
    }

    /// 지도와 스크롤에서 공유하는 고정 순서.
    var id: Int { (groupNumber - 1) * 4 + stepNumber - 1 }

    /// 난이도에 대응하는 스테이지 구역 번호.
    var groupNumber: Int {
        switch difficulty {
        case .easy: 1
        case .normal: 2
        case .hard: 3
        }
    }

    /// 기존 작업에 대응하는 구역 안의 단계 번호.
    var stepNumber: Int {
        switch task {
        case .wishReception: 1
        case .giftProduction: 2
        case .wrapping: 3
        case .sleighLoading: 4
        }
    }

    /// 난이도별 지도 구역과 세션 안내에 표시하는 장소 이름.
    var districtName: String {
        switch difficulty {
        case .easy: "소원 우체국"
        case .normal: "선물 제작소"
        case .hard: "루돌프 정류장"
        }
    }

    /// 기존 보상 작업과 난이도에 대응하는 단계 이름.
    var stepName: String {
        switch (difficulty, task) {
        case (.easy, .wishReception): "우편함 열기"
        case (.easy, .giftProduction): "주소 확인"
        case (.easy, .wrapping): "소원 기록"
        case (.easy, .sleighLoading): "접수 마감"
        case (.normal, .wishReception): "재료 준비"
        case (.normal, .giftProduction): "뚝딱 조립"
        case (.normal, .wrapping): "리본 포장"
        case (.normal, .sleighLoading): "품질 검사"
        case (.hard, .wishReception): "썰매 점검"
        case (.hard, .giftProduction): "선물 싣기"
        case (.hard, .wrapping): "루돌프 정렬"
        case (.hard, .sleighLoading): "출동 완료"
        }
    }

    /// 풀이·결과·이어 풀기에서 공통으로 표시하는 장소와 단계 이름.
    var title: String { "\(districtName) · \(stepName)" }

    /// 현재 트리에서 이 단계의 보상을 획득했는지 확인한다.
    func isEarned(in rewardMask: Int) -> Bool {
        rewardMask & task.rewardBit(for: difficulty) != 0
    }

    /// 획득 완료 단계 또는 첫 미획득 단계만 입장할 수 있다.
    func isUnlocked(in rewardMask: Int) -> Bool {
        isEarned(in: rewardMask) || Self.next(in: rewardMask) == self
    }

    /// 개수로 추정하지 않고 실제 보상 칸에서 다음 도전을 찾는다.
    static func next(in rewardMask: Int) -> QuizStage? {
        all.first { !$0.isEarned(in: rewardMask) }
    }

    /// 난이도 선택 시 다음 도전을 우선하고, 없으면 첫 재도전 단계를 반환한다.
    static func destination(for difficulty: Difficulty, rewardMask: Int) -> QuizStage? {
        if let next = next(in: rewardMask), next.difficulty == difficulty { return next }
        return all.first { $0.difficulty == difficulty && $0.isEarned(in: rewardMask) }
    }

    /// 기존 세션도 저장된 두 식별자로 단계를 복원할 수 있다.
    init(task: WorkshopTask, difficulty: Difficulty) {
        self.task = task
        self.difficulty = difficulty
    }
}
