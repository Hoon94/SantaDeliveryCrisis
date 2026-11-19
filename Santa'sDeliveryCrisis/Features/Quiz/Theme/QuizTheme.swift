import SwiftUI

/// 퀴즈 화면의 테마. 배경과 문제에 반응하는 캐릭터를 정한다.
///
/// 지금은 작업(카테고리)과 일대일로 연결한다. 테마를 카테고리와 따로 고르게 되면 `init(category:)`만 바꾸면 된다.
// FIXME: [자산 교체] 배경은 흐릿한 글자와 색으로 대신하고, 캐릭터는 이모지로 대신한다. 실제 일러스트가 오면 교체
enum QuizTheme: CaseIterable, Hashable {
    case wish, factory, wrap, sleigh

    /// 카테고리에 해당하는 테마
    init(category: QuizCategory) {
        switch category {
        case .aiUsage: self = .wish
        case .swiftSyntax: self = .factory
        case .hig: self = .wrap
        case .swiftUIPractice: self = .sleigh
        }
    }

    /// 테마의 카테고리
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
