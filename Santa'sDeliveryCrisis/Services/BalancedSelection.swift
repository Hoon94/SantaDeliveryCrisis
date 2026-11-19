import Foundation

extension QuestionSelecting {
    /// 선택한 카테고리들에서 문제를 고르게 나눠 고른다. 장식 카테고리와는 무관하다.
    ///
    /// - 문제 수를 카테고리 수로 나눠 각 카테고리에 배정하고, 나머지는 무작위로 고른 카테고리에 한 문제씩 더 준다.
    ///   예: 5문제 4카테고리는 2·1·1·1, 10문제 3카테고리는 4·3·3.
    /// - 카테고리 안에서의 선택(약한 문제, 오래 안 푼 문제)은 `select(category:...)`를 그대로 쓴다.
    /// - 어떤 카테고리의 후보가 모자라면 부족한 수를 다른 카테고리의 남은 후보로 채운다. 중복 출제는 없다.
    /// - 고른 문제의 최종 순서는 무작위로 섞는다.
    /// - Parameters:
    ///   - categories: 출제할 카테고리. 비어 있으면 빈 배열을 돌려준다.
    /// - Returns: 최대 `count`개. 전체 후보가 모자라면 가능한 만큼만 돌려준다.
    func select(
        categories: Set<QuizCategory>,
        difficulty: Difficulty,
        tags: Set<String>,
        count: Int,
        questions: [Question],
        history: [QuizSession]
    ) -> [Question] {
        let ordered = QuizCategory.allCases.filter { categories.contains($0) }
        guard !ordered.isEmpty, count > 0 else { return [] }
        if ordered.count == 1 {
            return select(category: ordered[0], difficulty: difficulty, tags: tags, count: count,
                          questions: questions, history: history)
        }

        let base = count / ordered.count
        let extraCategories = Set(ordered.shuffled().prefix(count % ordered.count))
        var chosen: [Question] = []
        for category in ordered {
            let quota = base + (extraCategories.contains(category) ? 1 : 0)
            guard quota > 0 else { continue }
            chosen += select(category: category, difficulty: difficulty, tags: tags, count: quota,
                             questions: questions, history: history)
        }

        var shortage = count - chosen.count
        if shortage > 0 {
            let used = Set(chosen.map(\.id))
            let remaining = questions.filter { !used.contains($0.id) }
            for category in ordered where shortage > 0 {
                let more = select(category: category, difficulty: difficulty, tags: tags, count: shortage,
                                  questions: remaining, history: history)
                chosen += more
                shortage -= more.count
            }
        }
        return chosen.shuffled()
    }

    /// 선택한 카테고리 전체에서 조건에 맞는 문제 수의 합.
    func availableCount(
        categories: Set<QuizCategory>,
        difficulty: Difficulty,
        tags: Set<String>,
        questions: [Question]
    ) -> Int {
        categories.reduce(0) {
            $0 + availableCount(category: $1, difficulty: difficulty, tags: tags, questions: questions)
        }
    }
}
