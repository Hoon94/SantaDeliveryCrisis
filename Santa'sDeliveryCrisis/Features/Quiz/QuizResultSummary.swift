import Foundation

/// 세션 결과 화면이 쓰는 요약. `SessionResult`에 화면에 필요한 세션 정보를 더한다.
struct QuizResultSummary {
    /// 서비스가 돌려준 결과
    let result: SessionResult
    /// 퀴즈를 시작할 때 선택한 보상 작업.
    let task: WorkshopTask
    /// 단일 학습 카테고리. 여러 카테고리를 고른 세션이면 nil이다.
    let category: QuizCategory?
    /// 난이도
    let difficulty: Difficulty
    /// 세션을 시작할 때 저장된 정답률 기준
    let thresholdPercent: Int
    /// 결과를 반영한 뒤 현재 트리의 장식 수. 트리가 완성됐다면 완성된 트리의 칸 수(12)
    let treeDecorationCount: Int

    /// 장식을 받았는가
    var isSuccess: Bool { result.earnedDecorations > 0 }

    /// 기준 통과 여부. 이미 보상을 받은 재풀이도 통과로 표시한다.
    var passedThreshold: Bool { result.passedThreshold }

    /// 신규 획득·이미 획득·기준 미달을 구별하는 안내.
    var rewardMessage: String {
        switch result.rewardOutcome {
        case .earned: "장식을 1개 받았어요"
        case .alreadyEarned: "이미 획득한 장식은 그대로예요. 추가 보상은 없어요"
        case .notEarned: "벌칙은 없어요. 다시 도전해 보세요"
        case .pending: "아직 결과가 확정되지 않았어요"
        }
    }

    /// 화면에 보여 줄 작업 이름
    var taskTitle: String { task.displayName }

    /// 카테고리 이름. 혼합 세션이면 설명 문구
    var categoryTitle: String { category?.categoryName ?? "여러 카테고리 섞음" }

    /// 소요 시간을 `분:초`로 나타낸 글
    var elapsedText: String {
        let total = max(Int(result.elapsed.rounded()), 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
