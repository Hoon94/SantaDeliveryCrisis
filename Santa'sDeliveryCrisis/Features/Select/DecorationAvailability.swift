/// 선택한 문제 수를 준비할 수 있는 카테고리의 장식만 활성화한다.
struct DecorationAvailability {
    /// 표시할 장식의 카테고리.
    let category: QuizCategory

    /// 해당 카테고리와 난이도로 준비할 수 있는 후보 수.
    let availableCount: Int

    /// 사용자가 선택한 문제 수.
    let requestedCount: Int

    /// 사용자가 해당 카테고리를 선택했는지 여부.
    let isSelected: Bool

    /// 요청한 수를 모두 준비할 수 있는 선택 카테고리만 활성화한다.
    var isEnabled: Bool {
        isSelected && availableCount >= requestedCount
    }

    /// 후보가 조금이라도 있지만 부족한 경우 표시할 안내 수.
    var shortageCount: Int? {
        guard isSelected, availableCount > 0, availableCount < requestedCount else { return nil }
        return availableCount
    }

    /// 카테고리가 선택됐고 후보 수가 요청 수 이상일 때만 진입을 허용한다.
    /// 사용자 결정: 후보 부족 시 가능한 만큼 출제하지 않고 장식을 끈다.
    static func calculate(
        category: QuizCategory,
        filter: SelectFilter,
        questions: [Question],
        selector: any QuestionSelecting
    ) -> DecorationAvailability {
        let availableCount = max(0, selector.availableCount(
            category: category,
            difficulty: filter.difficulty,
            tags: [],
            questions: questions
        ))
        return DecorationAvailability(
            category: category,
            availableCount: availableCount,
            requestedCount: filter.count,
            isSelected: filter.categories.contains(category)
        )
    }
}
