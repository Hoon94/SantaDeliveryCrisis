/// 장식 프리뷰에서 카테고리·난이도·태그 조건을 실제로 거르는 임시 선택기.
/// 기존 MockQuestionSelector가 카테고리와 난이도를 무시하므로 프리뷰에서만 사용한다.
// FIXME: [mock 교체] 실제 QuestionSelecting 통합 후 프리뷰 전용 선택기를 실제 구현으로 교체
struct PreviewQuestionSelector: QuestionSelecting {
    /// 조건에 맞는 앞쪽 문제만 반환한다. 실제 세션의 출제 비율과 기록 반영은 구현하지 않는다.
    func select(
        category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, count: Int,
        questions: [Question], history: [QuizSession]
    ) -> [Question] {
        Array(matchingQuestions(
            category: category, difficulty: difficulty, tags: tags, questions: questions
        ).prefix(max(0, count)))
    }

    /// 후보 조회와 문제 선택에 동일한 필터를 적용한다.
    func availableCount(
        category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, questions: [Question]
    ) -> Int {
        matchingQuestions(
            category: category, difficulty: difficulty, tags: tags, questions: questions
        ).count
    }

    private func matchingQuestions(
        category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, questions: [Question]
    ) -> [Question] {
        questions.filter { question in
            (category == nil || question.category == category)
                && question.difficulty == difficulty
                && (tags.isEmpty || question.tags.contains { tags.contains($0) })
        }
    }
}
