import Foundation

/// 출제 팝업(S2)의 [추천] 배지에 쓸 카테고리를 계산한다.
///
/// 답을 한 기록이 있는 카테고리 중 정답률이 가장 낮은 카테고리 하나를 돌려준다.
/// - 정답률이 같으면 작업 순서(소원 접수, 선물 생산, 포장, 썰매 적재)에서 앞선 카테고리
/// - 답한 기록이 전혀 없으면 nil. 화면은 nil이면 배지를 표시하지 않는다.
/// - 카테고리는 답한 문제의 스냅샷(`QuestionSnapshot.category`) 기준이다.
///   문제를 나중에 고치거나 지워도 풀 당시의 카테고리로 센다.
/// - 완료, 진행 중, 중단 세션을 가리지 않고 저장된 답을 모두 센다.
struct TaskRecommender: TaskRecommending {
    func recommendedCategory(sessions: [QuizSession]) -> QuizCategory? {
        var correct: [QuizCategory: Int] = [:]
        var total: [QuizCategory: Int] = [:]

        for session in sessions {
            let categoryByQuestion = Dictionary(
                session.questionSnapshots.map { ($0.questionID, $0.category) },
                uniquingKeysWith: { first, _ in first }
            )
            for answer in session.answers {
                guard let category = categoryByQuestion[answer.questionID] else { continue }
                total[category, default: 0] += 1
                if answer.isCorrect { correct[category, default: 0] += 1 }
            }
        }

        var best: QuizCategory?
        // CaseIterable 순서가 작업 순서이므로, 엄격히 낮을 때만 바꾸면 동률은 앞선 카테고리가 남는다.
        for category in QuizCategory.allCases {
            guard let attempts = total[category], attempts > 0 else { continue }
            guard let current = best else {
                best = category
                continue
            }
            let currentTotal = total[current] ?? 0
            // 정답률 비교를 분수 곱셈으로 해서 소수점 오차를 피한다: a/b < c/d  ⇔  a*d < c*b
            if (correct[category] ?? 0) * currentTotal < (correct[current] ?? 0) * attempts {
                best = category
            }
        }
        return best
    }
}
