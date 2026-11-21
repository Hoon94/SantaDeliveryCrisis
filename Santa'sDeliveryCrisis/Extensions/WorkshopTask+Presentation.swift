import SwiftUI

extension WorkshopTask {
    /// 기존 네 장식의 색을 유지한다. 문제 카테고리를 선택하는 데는 사용하지 않는다.
    var themeColor: Color {
        switch self {
        case .wishReception: .categoryAiUsage
        case .giftProduction: .categorySwiftSyntax
        case .wrapping: .categoryHig
        case .sleighLoading: .categorySwiftUIPractice
        }
    }

    /// 이어 풀기와 세션 요약에서 표시하는 작업 아이콘.
    var emoji: String {
        switch self {
        case .wishReception: "📮"
        case .giftProduction: "🎁"
        case .wrapping: "🎀"
        case .sleighLoading: "🛷"
        }
    }
}
