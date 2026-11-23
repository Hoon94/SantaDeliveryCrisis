import SwiftUI

/// 작업실과 출제 화면이 공유하는 카테고리 표현.
extension QuizCategory {
    /// 학습 카테고리와 퀴즈 테마에 사용하는 대표 색상.
    var themeColor: Color {
        switch self {
        case .aiUsage: .categoryAiUsage
        case .swiftSyntax: .categorySwiftSyntax
        case .hig: .categoryHig
        case .swiftUIPractice: .categorySwiftUIPractice
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
