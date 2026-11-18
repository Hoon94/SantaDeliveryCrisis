#if DEBUG
import Foundation
import SwiftData

/// 기록 화면 미리보기용 샘플 세션. 실제 기록이 쌓이기 전에도 차트와 목록을 확인할 수 있다.
enum RecordsPreviewData {
    /// 메모리 전용 컨테이너를 만든다. `withSessions`가 true면 최근 며칠간의 끝낸 세션을 넣는다.
    static func container(withSessions: Bool) -> ModelContainer {
        guard let container = try? ModelContainerFactory.make(inMemory: true) else {
            fatalError("미리보기용 컨테이너를 만들 수 없습니다")
        }
        guard withSessions else { return container }
        let context = container.mainContext
        let samples: [(daysAgo: Int, category: QuizCategory, correct: Int, total: Int)] = [
            (0, .swiftSyntax, 5, 5),
            (1, .hig, 3, 5),
            (2, .swiftUIPractice, 8, 10),
            (3, .aiUsage, 4, 5),
            (5, .hig, 2, 5),
        ]
        for sample in samples {
            context.insert(session(sample.daysAgo, sample.category, sample.correct, sample.total))
        }
        return container
    }

    private static func session(_ daysAgo: Int, _ category: QuizCategory, _ correct: Int, _ total: Int) -> QuizSession {
        let finishedAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let questions = (0..<total).map { index in
            Question(
                text: "샘플 문제 \(index + 1)",
                choices: ["가", "나", "다", "라"],
                correctIndex: 0,
                explanation: "샘플 해설",
                category: category,
                difficulty: .normal
            )
        }
        let session = QuizSession(
            category: category,
            difficulty: .normal,
            questionSnapshots: questions.map(QuestionSnapshot.init),
            passThresholdPercent: 80,
            startedAt: finishedAt
        )
        session.answers = questions.enumerated().map { index, question in
            SessionAnswer(
                questionID: question.id,
                selectedIndex: index < correct ? 0 : 1,
                isCorrect: index < correct,
                answeredAt: finishedAt
            )
        }
        session.status = .completed
        session.finishedAt = finishedAt
        session.currentIndex = total
        return session
    }
}
#endif
