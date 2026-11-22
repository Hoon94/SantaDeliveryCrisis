import Foundation

/// 문제의 학습 카테고리. 보상을 쌓는 작업은 WorkshopTask로 구분한다.
nonisolated enum QuizCategory: String, Codable, CaseIterable, Sendable {
    /// AI 활용
    case aiUsage
    /// Swift 문법
    case swiftSyntax
    /// HIG
    case hig
    /// SwiftUI 실전
    case swiftUIPractice

    /// 카테고리 이름
    var categoryName: String {
        switch self {
        case .aiUsage: "AI 활용"
        case .swiftSyntax: "Swift 문법"
        case .hig: "HIG"
        case .swiftUIPractice: "SwiftUI 실전"
        }
    }
}

/// 난이도. UI 표기는 쉬움, 보통, 어려움으로 통일한다.
nonisolated enum Difficulty: String, Codable, CaseIterable, Sendable {
    case easy, normal, hard

    /// UI에 표시하는 이름
    var displayName: String {
        switch self {
        case .easy: "쉬움"
        case .normal: "보통"
        case .hard: "어려움"
        }
    }
}

/// 문제 종류. `animation`은 코드 실행을 줄별 애니메이션으로 보여 주는 문제.
nonisolated enum QuestionKind: String, Codable, Sendable {
    case standard, animation
}

/// 세션 상태
nonisolated enum SessionStatus: String, Codable, Sendable {
    case inProgress, completed, abandoned
}
