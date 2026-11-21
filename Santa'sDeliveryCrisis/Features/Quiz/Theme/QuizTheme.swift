import SwiftUI

/// 문항 진행에 따른 작업 과정. 배경과 캐릭터는 문제 카테고리와 독립적으로 정한다.
enum QuizTheme: CaseIterable, Hashable {
    case wish, factory, wrap, sleigh

    /// 기존 결과 화면의 배경을 보존하기 위한 카테고리 연결. 풀이 과정 계산에는 사용하지 않는다.
    init(category: QuizCategory) {
        switch category {
        case .aiUsage: self = .wish
        case .swiftSyntax: self = .factory
        case .hig: self = .wrap
        case .swiftUIPractice: self = .sleigh
        }
    }

    /// 실제 세션 문항 수를 네 과정에 균등하게 나누고, 남는 문항은 뒤쪽 과정부터 배정한다.
    /// 문항 번호는 0부터 시작한다. 빈 세션은 기본 과정, 범위 밖 번호는 처음 또는 마지막 문항을 따른다.
    init(questionIndex: Int, totalCount: Int) {
        guard totalCount > 0 else {
            self = .wish
            return
        }

        let themes = Self.allCases
        let baseCount = totalCount / themes.count
        let remainder = totalCount % themes.count
        let index = min(max(questionIndex, 0), totalCount - 1)
        var endIndex = 0

        for (offset, theme) in themes.enumerated() {
            endIndex += baseCount + (offset >= themes.count - remainder ? 1 : 0)
            if index < endIndex {
                self = theme
                return
            }
        }

        self = .sleigh
    }

    /// 기존 과정별 이름과 색을 가져오는 표시용 연결. 현재 문제의 카테고리를 뜻하지 않는다.
    var category: QuizCategory {
        switch self {
        case .wish: .aiUsage
        case .factory: .swiftSyntax
        case .wrap: .hig
        case .sleigh: .swiftUIPractice
        }
    }

    /// 작업 이름. 배경의 흐릿한 글자와 화면 제목에 쓴다.
    var title: String { category.taskName }

    /// 테마를 대표하는 색
    var accent: Color { category.themeColor }

    /// 문제 풀이에서만 사용하는 픽셀 배경 이름.
    var backgroundName: String {
        switch self {
        case .wish: "QuizWishBackground"
        case .factory: "QuizFactoryBackground"
        case .wrap: "QuizWrapBackground"
        case .sleigh: "QuizSleighBackground"
        }
    }

    /// 두 자세가 가로로 나란히 배치된 캐릭터 이미지 이름.
    var characterImageName: String {
        switch self {
        case .wish: "QuizWishCharacter"
        case .factory: "QuizFactoryCharacter"
        case .wrap: "QuizWrapCharacter"
        case .sleigh: "QuizSleighCharacter"
        }
    }

    /// 접근성 설명에 쓰는 담당 캐릭터 이름.
    var characterName: String {
        switch self {
        case .wish: "산타"
        case .factory: "생산 엘프"
        case .wrap: "포장 엘프"
        case .sleigh: "루돌프"
        }
    }

    /// 새 문제에서 보여 주는 기본 대사.
    var idleLine: String {
        switch self {
        case .wish: "오늘은 어떤 소원이 왔을까?"
        case .factory: "좋아, 선물을 만들 준비가 됐어!"
        case .wrap: "이 선물에는 어떤 리본이 어울릴까?"
        case .sleigh: "선물들을 싣고 출발할 준비를 하자!"
        }
    }

    /// 배경 위쪽에 흐릿하게 박아 두는 소품 이모지
    var props: [String] {
        switch self {
        case .wish: ["✉️", "📜", "🕯️"]
        case .factory: ["🧸", "🚂", "⚙️"]
        case .wrap: ["🎁", "🎀", "✂️"]
        case .sleigh: ["🛷", "📦", "❄️"]
        }
    }

    /// 보기 변경마다 순환하는 고민 대사. 정답 여부를 암시하지 않는다.
    var thinkingLines: [String] {
        switch self {
        case .wish: ["편지를 차근차근 읽어 보자.", "다른 소원과 헷갈린 건 아닐까?", "급하지 않아. 한 번 더 살펴보자.", "중요한 단어를 찾아볼까?", "어떤 뜻인지 같이 생각해 보자."]
        case .factory: ["부품 하나씩 비교해 보자.", "조립 순서를 다시 떠올려 볼까?", "다른 방법도 천천히 살펴보자.", "서두르지 말고 모양을 맞춰 보자.", "작은 차이가 있을지도 몰라."]
        case .wrap: ["모서리까지 꼼꼼히 살펴보자.", "리본을 묶기 전에 한 번 더 생각해 보자.", "비슷해 보여도 다른 점이 있을까?", "천천히 골라도 괜찮아.", "포장 순서를 떠올려 보면 어떨까?"]
        case .sleigh: ["짐의 균형을 다시 살펴보자.", "출발 전에는 차근차근 확인해야지.", "다른 자리에 놓으면 어떨까?", "천천히 생각해. 아직 출발 전이니까!", "놓친 선물이 없는지 한 번 더 볼까?"]
        }
    }
}
