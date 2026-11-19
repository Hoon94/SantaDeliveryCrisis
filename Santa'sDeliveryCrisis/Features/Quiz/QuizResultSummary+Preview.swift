#if DEBUG
import Foundation

/// 미리보기용 결과 요약 샘플
extension QuizResultSummary {
    /// 4/5 정답으로 기준(80%)을 넘긴 결과
    static var previewSuccess: QuizResultSummary {
        QuizResultSummary(
            result: SessionResult(
                correctCount: 4, totalCount: 5, accuracyPercent: 80, elapsed: 192,
                earnedDecorations: 1, treeCompleted: false,
                wrongAnswers: [SessionAnswer(questionID: UUID(), selectedIndex: 2, isCorrect: false)]
            ),
            category: .aiUsage,
            difficulty: .normal,
            thresholdPercent: 80,
            treeDecorationCount: 5
        )
    }

    /// 3/5 정답으로 기준에 못 미친 결과
    static var previewFailure: QuizResultSummary {
        QuizResultSummary(
            result: SessionResult(
                correctCount: 3, totalCount: 5, accuracyPercent: 60, elapsed: 221,
                earnedDecorations: 0, treeCompleted: false,
                wrongAnswers: [
                    SessionAnswer(questionID: UUID(), selectedIndex: 0, isCorrect: false),
                    SessionAnswer(questionID: UUID(), selectedIndex: 3, isCorrect: false)
                ]
            ),
            category: .swiftSyntax,
            difficulty: .normal,
            thresholdPercent: 80,
            treeDecorationCount: 4
        )
    }

    /// 전부 맞히고 트리까지 완성한 결과(여러 카테고리 섞음)
    static var previewTreeComplete: QuizResultSummary {
        QuizResultSummary(
            result: SessionResult(
                correctCount: 5, totalCount: 5, accuracyPercent: 100, elapsed: 168,
                earnedDecorations: 1, treeCompleted: true, wrongAnswers: []
            ),
            category: nil,
            difficulty: .hard,
            thresholdPercent: 80,
            treeDecorationCount: 12
        )
    }
}
#endif
