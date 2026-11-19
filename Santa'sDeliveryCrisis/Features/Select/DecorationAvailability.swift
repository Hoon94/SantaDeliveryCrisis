/// 장식의 켜짐 상태.
///
/// 장식은 문제 카테고리와 연동하지 않는다. 문제는 사용자가 고른 카테고리 전체에서 고르게 출제하므로,
/// 켜짐 여부는 "고른 카테고리 전체의 후보 수가 문제 수 이상인가" 하나로 정해지고 네 장식이 모두 같은 상태를 가진다.
struct DecorationAvailability {
    /// 표시할 장식. 어떤 장식인지 구별하는 용도이며 출제 카테고리와는 무관하다.
    let category: QuizCategory

    /// 선택한 카테고리 전체에서 선택한 난이도로 준비할 수 있는 후보 수.
    let availableCount: Int

    /// 사용자가 선택한 문제 수.
    let requestedCount: Int

    /// 후보 수가 요청한 문제 수 이상이면 켜진다.
    var isEnabled: Bool {
        availableCount >= requestedCount
    }

    /// 후보가 조금이라도 있지만 요청 수보다 적을 때 안내할 후보 수. 없거나 충분하면 nil.
    var shortageCount: Int? {
        guard availableCount > 0, availableCount < requestedCount else { return nil }
        return availableCount
    }

    /// 선택한 카테고리 전체의 후보 수를 한 번 조회해 네 장식에 같은 값을 준다.
    /// - Parameters:
    ///   - filter: 화면에서 적용한 카테고리·난이도·문제 수.
    ///   - questions: 현재 저장된 전체 문제.
    ///   - selector: 후보 수를 계산하는 서비스.
    /// - Returns: 장식 순서가 고정된 표시 정보. 후보 수는 음수가 되지 않게 0으로 보정한다.
    static func calculate(
        filter: SelectFilter,
        questions: [Question],
        selector: any QuestionSelecting
    ) -> [DecorationAvailability] {
        let availableCount = max(0, selector.availableCount(
            categories: filter.categories,
            difficulty: filter.difficulty,
            tags: [],
            questions: questions
        ))
        return QuizCategory.allCases.map { category in
            DecorationAvailability(
                category: category,
                availableCount: availableCount,
                requestedCount: filter.count
            )
        }
    }
}
