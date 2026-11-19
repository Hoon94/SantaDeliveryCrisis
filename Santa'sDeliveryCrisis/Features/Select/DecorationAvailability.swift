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

    /// 네 카테고리를 모델 순서대로 각각 조회하고 비선택 카테고리도 결과에 포함한다.
    /// - Parameters:
    ///   - filter: 화면에서 적용한 카테고리·난이도·문제 수.
    ///   - questions: 현재 저장된 전체 문제.
    ///   - selector: 카테고리별 후보 수를 계산하는 서비스.
    /// - Returns: 카테고리 순서가 고정된 장식 표시 정보.
    static func calculate(
        filter: SelectFilter,
        questions: [Question],
        selector: any QuestionSelecting
    ) -> [DecorationAvailability] {
        QuizCategory.allCases.map { category in
            calculate(category: category, filter: filter, questions: questions, selector: selector)
        }
    }

    /// 카테고리 하나의 후보 수를 조회해 활성 여부와 부족 안내를 구성한다.
    /// - Parameters:
    ///   - category: 조회할 카테고리.
    ///   - filter: 적용한 설정. 후보 수가 요청 수보다 작으면 장식을 끈다.
    ///   - questions: 선택기에 전달할 전체 문제.
    ///   - selector: 실제 후보 필터를 적용하는 서비스.
    /// - Returns: 음수 후보 수를 0으로 보정한 표시 정보. 모델은 변경하지 않는다.
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
