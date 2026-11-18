import Foundation

/// 현재 문제 목록과 풀이 기록으로 계산한 난이도별 미풀이 문제 수.
struct UnsolvedQuestionStats {
    /// 난이도 하나의 문제 수와 풀이 진행 비율.
    struct Entry {
        /// 집계 대상 난이도.
        let difficulty: Difficulty
        /// 한 번도 답을 제출하지 않은 문제 수.
        let unsolved: Int
        /// 현재 목록에 있는 전체 문제 수.
        let total: Int

        /// 전체 문제 중 답을 제출한 문제의 비율. 문제가 없으면 0.
        var solvedFraction: Double {
            guard total > 0 else { return 0 }
            return Double(total - unsolved) / Double(total)
        }
    }

    /// 쉬움, 보통, 어려움 순서의 집계. 문제가 없는 난이도도 포함한다.
    let byDifficulty: [Entry]

    /// 네 작업과 모든 난이도를 합친 미풀이 문제 수.
    var unsolved: Int {
        byDifficulty.reduce(0) { $0 + $1.unsolved }
    }

    /// 네 작업과 모든 난이도를 합친 전체 문제 수.
    var total: Int {
        byDifficulty.reduce(0) { $0 + $1.total }
    }

    /// 모델을 변경하거나 저장하지 않고 현재 문제의 미풀이 통계를 계산한다.
    /// 완료·진행 중·중단 상태와 정오답에 관계없이 저장된 답이 있으면 푼 문제로 본다.
    /// - Parameters:
    ///   - questions: 현재 저장된 문제. 삭제된 문제의 답은 집계에서 제외한다.
    ///   - history: 세션 상태로 거르지 않은 전체 풀이 기록.
    /// - Returns: 모든 난이도를 포함하고 문제 ID를 중복 집계하지 않는 통계.
    static func calculate(questions: [Question], history: [QuizSession]) -> UnsolvedQuestionStats {
        let answeredIDs = Set(history.flatMap { session in
            session.answers.map(\.questionID)
        })
        let entries = Difficulty.allCases.map { difficulty in
            let questionIDs = Set(
                questions.filter { $0.difficulty == difficulty }.map(\.id)
            )
            return Entry(
                difficulty: difficulty,
                unsolved: questionIDs.subtracting(answeredIDs).count,
                total: questionIDs.count
            )
        }
        return UnsolvedQuestionStats(byDifficulty: entries)
    }
}
