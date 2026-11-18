import SwiftUI

/// 화면들이 함께 사용하는 카테고리의 표현 색상.
extension QuizCategory {
    /// 작업(카테고리)을 대표하는 색.
    var themeColor: Color {
        switch self {
        case .aiUsage: .categoryAiUsage
        case .swiftSyntax: .categorySwiftSyntax
        case .hig: .categoryHig
        case .swiftUIPractice: .categorySwiftUIPractice
        }
    }
}
