import Foundation

/// 세션 시작 시점의 문제 내용 복사본.
/// 원본 문제를 나중에 고치거나 지워도 진행 중 세션과 풀 당시의 문제 내용이 바뀌지 않게 한다.
/// 이미지·영상 파일은 복사하지 않고 파일명만 가진다.
nonisolated struct QuestionSnapshot: Codable, Sendable {
    /// 통계 계산용 원본 id
    let questionID: UUID
    /// 카테고리별 통계용. 혼합 세션에서도 문제별 카테고리를 알 수 있다.
    let category: QuizCategory
    let kind: QuestionKind
    /// 풀 당시의 태그
    let tags: [String]
    let animationID: String?
    let text: String
    let codeSnippet: String?
    let imageFileName: String?
    let videoFileName: String?
    let hint: String?
    let choices: [String]
    let correctIndex: Int
    let explanation: String
    let resourceTitle: String?
    let resourceURL: String?

    /// 원본 문제에서 복사본을 만든다.
    init(_ question: Question) {
        self.questionID = question.id
        self.category = question.category
        self.kind = question.kind
        self.tags = question.tags
        self.animationID = question.animationID
        self.text = question.text
        self.codeSnippet = question.codeSnippet
        self.imageFileName = question.imageFileName
        self.videoFileName = question.videoFileName
        self.hint = question.hint
        self.choices = question.choices
        self.correctIndex = question.correctIndex
        self.explanation = question.explanation
        self.resourceTitle = question.resourceTitle
        self.resourceURL = question.resourceURL
    }
}
