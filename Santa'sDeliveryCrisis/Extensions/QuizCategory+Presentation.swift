import SwiftUI

/// 작업실과 출제 화면이 공유하는 카테고리 표현.
extension QuizCategory {
    /// 작업 장식과 선택 상태에 사용하는 대표 색상.
    var themeColor: Color {
        switch self {
        case .aiUsage: .categoryAiUsage
        case .swiftSyntax: .categorySwiftSyntax
        case .hig: .categoryHig
        case .swiftUIPractice: .categorySwiftUIPractice
        }
    }

    /// 작업실·장식·이어 풀기에서 사용하는 작업 아이콘.
    var taskEmoji: String {
        switch self {
        case .aiUsage: "📮"
        case .swiftSyntax: "🎁"
        case .hig: "🎀"
        case .swiftUIPractice: "🛷"
        }
    }

    /// 출제 조건에서 학습 분야를 구분하는 카테고리 아이콘.
    var categoryEmoji: String {
        switch self {
        case .aiUsage: "🤖"
        case .swiftSyntax: "🐦"
        case .hig: "🎨"
        case .swiftUIPractice: "🧩"
        }
    }
}
