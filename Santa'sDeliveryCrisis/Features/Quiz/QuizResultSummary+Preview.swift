#if DEBUG
import Foundation

/// 미리보기용 결과 요약 샘플
extension QuizResultSummary {
    /// 4/5 정답으로 기준(80%)을 넘긴 결과
    static var previewSuccess: QuizResultSummary {
        QuizResultSummary(
            result: SessionResult(
                correctCount: 4, totalCount: 5, accuracyPercent: 80, elapsed: 192,
                passedThreshold: true, rewardOutcome: .earned,
                earnedDecorations: 1, treeCompleted: false,
                wrongAnswers: [SessionAnswer(questionID: UUID(), selectedIndex: 2, isCorrect: false)]
            ),
            task: .wishReception,
            category: .aiUsage,
            difficulty: .normal,
            thresholdPercent: 80,
            treeRewardMask: previewRewardMask(count: 5)
        )
    }

    /// 3/5 정답으로 기준에 못 미친 결과
    static var previewFailure: QuizResultSummary {
        QuizResultSummary(
            result: SessionResult(
                correctCount: 3, totalCount: 5, accuracyPercent: 60, elapsed: 221,
                passedThreshold: false, rewardOutcome: .notEarned,
                earnedDecorations: 0, treeCompleted: false,
                wrongAnswers: [
                    SessionAnswer(questionID: UUID(), selectedIndex: 0, isCorrect: false),
                    SessionAnswer(questionID: UUID(), selectedIndex: 3, isCorrect: false)
                ]
            ),
            task: .giftProduction,
            category: .swiftSyntax,
            difficulty: .normal,
            thresholdPercent: 80,
            treeRewardMask: previewRewardMask(count: 4)
        )
    }

    /// 전부 맞히고 트리까지 완성한 결과(여러 카테고리 섞음)
    static var previewTreeComplete: QuizResultSummary {
        QuizResultSummary(
            result: SessionResult(
                correctCount: 5, totalCount: 5, accuracyPercent: 100, elapsed: 168,
                passedThreshold: true, rewardOutcome: .earned,
                earnedDecorations: 1, treeCompleted: true, wrongAnswers: []
            ),
            task: .sleighLoading,
            category: nil,
            difficulty: .hard,
            thresholdPercent: 80,
            treeRewardMask: previewRewardMask(count: 12)
        )
    }

    /// 통과했지만 현재 트리에서 이미 보상을 받은 조합이다.
    static var previewPracticePassed: QuizResultSummary {
        practiceSummary(passed: true)
    }

    /// 이미 보상을 받은 조합을 다시 풀어 기준에 못 미쳐도 장식은 유지된다.
    static var previewPracticeFailed: QuizResultSummary {
        practiceSummary(passed: false)
    }

    private static func practiceSummary(passed: Bool) -> QuizResultSummary {
        QuizResultSummary(
            result: SessionResult(
                correctCount: passed ? 4 : 3, totalCount: 5, accuracyPercent: passed ? 80 : 60, elapsed: 180,
                passedThreshold: passed, rewardOutcome: .alreadyEarned,
                earnedDecorations: 0, treeCompleted: false, wrongAnswers: []
            ),
            task: .giftProduction, category: nil, difficulty: .normal,
            thresholdPercent: 80, treeRewardMask: previewRewardMask(count: 6)
        )
    }

    /// 지도 순서로 획득한 샘플을 만든다. 실제 저장 비트는 작업별 순서라 개수로 추정하지 않는다.
    private static func previewRewardMask(count: Int) -> Int {
        QuizStage.all.prefix(count).reduce(0) { mask, stage in
            mask | stage.task.rewardBit(for: stage.difficulty)
        }
    }
}
#endif
