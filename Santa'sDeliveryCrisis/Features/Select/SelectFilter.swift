/// 출제할 난이도, 하나 이상의 카테고리, 문제 수를 담는 설정 값.
struct SelectFilter: Equatable {
    /// 화면에 표시할 수 있는 문제 수. 표시 순서를 유지한다.
    static let allowedCounts = [5, 10, 15]

    /// 출제할 난이도. 화면의 선택 순서는 Difficulty.allCases를 따른다.
    var difficulty: Difficulty

    /// 선택한 카테고리 집합. 변경 함수를 통해 최소 하나를 유지한다.
    private(set) var categories: Set<QuizCategory>

    /// 출제할 문제 수. 허용된 값 이외에는 기본값인 5를 사용한다.
    private(set) var count: Int

    /// 기본 설정은 보통, 전체 카테고리, 5문제다. 빈 카테고리는 전체 선택으로 보정한다.
    /// - Parameters:
    ///   - difficulty: 출제할 난이도.
    ///   - categories: 하나 이상의 카테고리. 비어 있으면 전체 카테고리를 사용한다.
    ///   - count: 5·10·15 중 문제 수. 그 외 값은 5로 보정한다.
    init(
        difficulty: Difficulty = .normal,
        categories: Set<QuizCategory> = Set(QuizCategory.allCases),
        count: Int = 5
    ) {
        self.difficulty = difficulty
        self.categories = categories.isEmpty ? Set(QuizCategory.allCases) : categories
        self.count = Self.allowedCounts.contains(count) ? count : 5
    }

    /// 선택을 반전하되 마지막으로 남은 카테고리의 해제는 무시한다.
    /// - Parameter category: 선택 또는 해제할 카테고리.
    mutating func toggleCategory(_ category: QuizCategory) {
        if categories.contains(category) {
            guard categories.count > 1 else { return }
            categories.remove(category)
        } else {
            categories.insert(category)
        }
    }

    /// 문제 수를 변경하며 허용되지 않은 값은 5로 보정한다.
    /// - Parameter count: 요청한 문제 수.
    mutating func setCount(_ count: Int) {
        self.count = Self.allowedCounts.contains(count) ? count : 5
    }
}

/// 마지막 적용값과 팝업에서 편집 중인 값을 독립적으로 관리한다.
/// 탭 이동이나 세션 시작에 따른 초기화는 수행하지 않는다.
struct SelectFilterState {
    /// 장식 선택과 세션 시작에 사용할 마지막 적용값.
    private(set) var applied: SelectFilter

    /// 팝업에서 수정하는 설정. 적용 전에는 applied에 영향을 주지 않는다.
    var editing: SelectFilter

    /// 처음 취소해도 기본 설정이 남도록 두 값을 같은 유효한 설정으로 시작한다.
    /// - Parameter applied: 최초 적용값. 생략하면 기본 출제 설정을 사용한다.
    init(applied: SelectFilter = SelectFilter()) {
        self.applied = applied
        self.editing = applied
    }

    /// 팝업을 열 때 마지막 적용값을 새 편집의 시작점으로 사용한다.
    mutating func beginEditing() {
        editing = applied
    }

    /// 편집값을 확정한다. 이후 취소는 이 설정으로 돌아간다.
    mutating func apply() {
        applied = editing
    }

    /// 편집 중 변경을 버리고 마지막 적용값으로 되돌린다.
    mutating func cancel() {
        editing = applied
    }
}
