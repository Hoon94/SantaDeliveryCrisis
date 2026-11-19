import Foundation

/// 세션 결과 화면이 쓰는 요약. `SessionResult`에 화면에 필요한 세션 정보를 더한다.
struct QuizResultSummary {
    /// 서비스가 돌려준 결과
    let result: SessionResult
    /// 세션의 작업. nil이면 여러 카테고리를 골라 섞어 낸 세션("여러 카테고리 섞음")
    let category: QuizCategory?
    /// 난이도
    let difficulty: Difficulty
    /// 세션을 시작할 때 저장된 정답률 기준
    let thresholdPercent: Int
    /// 결과를 반영한 뒤 현재 트리의 장식 수. 트리가 완성됐다면 완성된 트리의 칸 수(12)
    let treeDecorationCount: Int

    /// 장식을 받았는가
    var isSuccess: Bool { result.earnedDecorations > 0 }

    /// 화면에 보여 줄 작업 이름
    var taskTitle: String { category?.taskName ?? "여러 카테고리 섞음" }

    /// 카테고리 이름. 혼합 세션이면 설명 문구
    var categoryTitle: String { category?.categoryName ?? "여러 카테고리 섞음" }

    /// 소요 시간을 `분:초`로 나타낸 글
    var elapsedText: String {
        let total = max(Int(result.elapsed.rounded()), 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
