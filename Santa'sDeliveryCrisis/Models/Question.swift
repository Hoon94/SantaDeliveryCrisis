import Foundation
import SwiftData

/// 퀴즈 문제 원본. 시드 문제와 사용자가 만든 문제를 모두 담는다.
@Model final class Question {
    @Attribute(.unique) var id: UUID
    var kind: QuestionKind
    var text: String
    /// 코드 문제의 코드
    var codeSnippet: String?
    /// 앱 내부 폴더 상의 이미지 파일명
    var imageFileName: String?
    var videoFileName: String?
    /// 항상 4개
    var choices: [String]
    /// 0...3
    var correctIndex: Int
    var explanation: String
    var hint: String?
    /// 추천 학습 자료 제목
    var resourceTitle: String?
    var resourceURL: String?
    var category: QuizCategory
    var difficulty: Difficulty
    var tags: [String]
    /// `kind == .animation`일 때만 사용
    var animationID: String?
    var isSeed: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        kind: QuestionKind = .standard,
        text: String,
        codeSnippet: String? = nil,
        imageFileName: String? = nil,
        videoFileName: String? = nil,
        choices: [String],
        correctIndex: Int,
        explanation: String,
        hint: String? = nil,
        resourceTitle: String? = nil,
        resourceURL: String? = nil,
        category: QuizCategory,
        difficulty: Difficulty,
        tags: [String] = [],
        animationID: String? = nil,
        isSeed: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.codeSnippet = codeSnippet
        self.imageFileName = imageFileName
        self.videoFileName = videoFileName
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.hint = hint
        self.resourceTitle = resourceTitle
        self.resourceURL = resourceURL
        self.category = category
        self.difficulty = difficulty
        self.tags = tags
        self.animationID = animationID
        self.isSeed = isSeed
        self.createdAt = createdAt
    }
}
