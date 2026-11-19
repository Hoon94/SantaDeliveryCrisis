import Foundation
import SwiftData

/// 한 판(세션)의 진행과 결과
@Model final class QuizSession {
    @Attribute(.unique) var id: UUID
    /// nil이면 여러 카테고리를 골라 섞어 낸 세션(카테고리가 하나면 그 카테고리)
    var category: QuizCategory?
    var difficulty: Difficulty
    /// 출제 순서 고정
    var questionIDs: [UUID]
    /// `questionIDs`와 같은 순서의 문제 복사본
    var questionSnapshots: [QuestionSnapshot]
    var currentIndex: Int
    var status: SessionStatus
    /// 시작 시점의 정답률 기준값
    var passThresholdPercent: Int
    var startedAt: Date
    var finishedAt: Date?
    /// 퀴즈 화면이 떠 있던 시간의 누적. 앱이 꺼져 있던 시간은 제외
    var elapsedSeconds: TimeInterval
    /// 완료 시 확정
    var earnedDecorations: Int
    /// 완료 시 확정. 이 세션으로 트리가 완성되었는가
    var treeCompleted: Bool
    @Relationship(deleteRule: .cascade) var answers: [SessionAnswer]

    init(
        id: UUID = UUID(),
        category: QuizCategory?,
        difficulty: Difficulty,
        questionSnapshots: [QuestionSnapshot],
        passThresholdPercent: Int,
        startedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.difficulty = difficulty
        self.questionIDs = questionSnapshots.map(\.questionID)
        self.questionSnapshots = questionSnapshots
        self.currentIndex = 0
        self.status = .inProgress
        self.passThresholdPercent = passThresholdPercent
        self.startedAt = startedAt
        self.finishedAt = nil
        self.elapsedSeconds = 0
        self.earnedDecorations = 0
        self.treeCompleted = false
        self.answers = []
    }
}

/// 문제 하나에 대한 답. 한 세션에서 같은 `questionID`의 답은 하나만 존재한다.
@Model final class SessionAnswer {
    var questionID: UUID
    var selectedIndex: Int
    var isCorrect: Bool
    var answeredAt: Date

    init(questionID: UUID, selectedIndex: Int, isCorrect: Bool, answeredAt: Date = Date()) {
        self.questionID = questionID
        self.selectedIndex = selectedIndex
        self.isCorrect = isCorrect
        self.answeredAt = answeredAt
    }
}
