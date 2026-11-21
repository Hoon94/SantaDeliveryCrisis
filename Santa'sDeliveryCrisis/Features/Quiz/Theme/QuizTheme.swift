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

    /// 캐릭터를 대신하는 이모지
    var character: String {
        switch self {
        case .wish: "🎅"
        case .factory: "🧝"
        case .wrap: "🧝‍♀️"
        case .sleigh: "🦌"
        }
    }

    /// 접근성 설명에 쓰는 캐릭터 이름
    var characterName: String {
        switch self {
        case .wish: "산타"
        case .factory, .wrap: "엘프"
        case .sleigh: "루돌프"
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

    /// 문제를 푸는 동안 캐릭터 말풍선
    var thinkingLines: [String] {
        switch self {
        case .wish: ["어떤 소원일까…", "흠, 잘 읽어 보자", "편지를 살펴볼게요"]
        case .factory: ["부품을 확인해요", "조립 순서가…", "차근차근 해 봐요"]
        case .wrap: ["어떻게 쌀까요?", "리본이 어디 있더라", "꼼꼼하게 볼게요"]
        case .sleigh: ["짐이 무겁네요", "출발 전 점검!", "균형을 맞춰요"]
        }
    }

    /// 정답일 때 말풍선
    var correctLines: [String] {
        switch self {
        case .wish: ["소원 접수 완료!", "잘 읽었어요!", "호호호, 정답!"]
        case .factory: ["선물 완성!", "딱 맞아요!", "조립 성공!"]
        case .wrap: ["포장 완료!", "리본이 예뻐요!", "깔끔해요!"]
        case .sleigh: ["적재 완료!", "출발 준비 끝!", "좋아요!"]
        }
    }

    /// 오답일 때 말풍선
    var wrongLines: [String] {
        switch self {
        case .wish: ["어라, 편지가 섞였네", "다음엔 잘 읽어 봐요"]
        case .factory: ["앗, 부품이 안 맞아요", "다시 해 보면 돼요"]
        case .wrap: ["포장지가 모자라요", "괜찮아요, 다시!"]
        case .sleigh: ["짐이 기울었어요", "다시 정리해요"]
        }
    }
}
