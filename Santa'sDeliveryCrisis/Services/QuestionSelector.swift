import Foundation

/// 문제 하나의 풀이 기록 요약. 세션 기록(`SessionAnswer`)에서 계산하고 따로 저장하지 않는다.
nonisolated struct QuestionHistoryStats: Sendable {
    /// 맞힌 횟수
    var correctCount = 0
    /// 푼 횟수
    var totalCount = 0
    /// 마지막으로 푼 시각
    var lastAnsweredAt: Date?
    /// 마지막 풀이가 정답이었는가
    var lastAnswerWasCorrect = true

    /// 세션 기록 전체에서 `questionID`별 요약을 만든다.
    /// 진행 중이거나 중단한 세션이라도 답이 저장된 문제는 푼 것으로 센다.
    @MainActor
    static func build(from sessions: [QuizSession]) -> [UUID: QuestionHistoryStats] {
        var result: [UUID: QuestionHistoryStats] = [:]
        for session in sessions {
            for answer in session.answers {
                var stats = result[answer.questionID] ?? QuestionHistoryStats()
                stats.totalCount += 1
                if answer.isCorrect { stats.correctCount += 1 }
                if let last = stats.lastAnsweredAt, last > answer.answeredAt {
                    // 이미 더 최근 풀이가 기록되어 있음
                } else {
                    stats.lastAnsweredAt = answer.answeredAt
                    stats.lastAnswerWasCorrect = answer.isCorrect
                }
                result[answer.questionID] = stats
            }
        }
        return result
    }
}

/// 세션에 낼 문제를 고른다. 규칙은 `docs/specs/02-session-engine.md`의 "출제"를 따른다.
///
/// **범주 두 개** (1차는 카테고리 하나를 고른 선택 출제)
/// - 약한 문제: 풀이 기록이 있고, 마지막 풀이가 오답이거나 정답률이 `SelectionCriteria.weakAccuracyPercent`% 미만
/// - 오래 안 푼 문제: 마지막 풀이가 `SelectionCriteria.staleDays`일 이상 지났거나 한 번도 안 푼 문제
///
/// **개수**: 뽑을 수 = min(요청 수, 후보 수). 오래 안 푼 쪽은 절반(내림), 나머지는 약한 문제 쪽이다(5개면 3·2).
///
/// **규칙**
/// - 약한 문제이면서 오래 안 푼 문제이면 약한 문제로 먼저 배정한다. 중복 출제는 없다.
/// - 한 범주가 모자라면 다른 범주의 남은 문제로 채우고, 그래도 모자라면 나머지 후보에서 채운다.
/// - 범주 안에서는 약한 문제는 정답률이 낮은 순, 오래 안 푼 문제는 안 푼 문제 먼저 그리고 오래된 순으로 뽑는다.
///   먼저 무작위로 섞은 뒤 정렬하므로 같은 조건끼리는 순서가 무작위다.
/// - 기록이 없으면 모든 문제가 "한 번도 안 푼 문제"라서 무작위로 고른다.
/// - 고른 문제의 최종 순서는 무작위로 섞는다.
///
/// - Note: "약한 문제"에 "마지막 풀이가 오답"을 넣은 것은 스펙의 "최근 오답이거나 정답률이 낮은 문제"를 옮긴 해석이다.
struct QuestionSelector: QuestionSelecting {
    private let now: () -> Date
    private let shuffle: ([Question]) -> [Question]

    /// - Parameters:
    ///   - now: 현재 시각. 테스트에서 고정 값을 넘긴다.
    ///   - shuffle: 문제를 섞는 방법. 테스트에서 고정 순서를 넘긴다.
    init(
        now: @escaping () -> Date = { Date() },
        shuffle: @escaping ([Question]) -> [Question] = { $0.shuffled() }
    ) {
        self.now = now
        self.shuffle = shuffle
    }

    func select(
        category: QuizCategory?,
        difficulty: Difficulty,
        tags: Set<String>,
        count: Int,
        questions: [Question],
        history: [QuizSession]
    ) -> [Question] {
        let pool = candidates(category: category, difficulty: difficulty, tags: tags, questions: questions)
        let total = min(max(count, 0), pool.count)
        guard total > 0 else { return [] }

        let stats = QuestionHistoryStats.build(from: history)
        let currentDate = now()

        var weak: [Question] = []
        var stale: [Question] = []
        var rest: [Question] = []
        for question in shuffle(pool) {
            let record = stats[question.id]
            if let record, isWeak(record) {
                weak.append(question)
            } else if record == nil
                        || SelectionCriteria.isStale(lastSolvedAt: record?.lastAnsweredAt, now: currentDate) {
                stale.append(question)
            } else {
                rest.append(question)
            }
        }

        // 약한 문제는 정답률이 낮은 순, 오래 안 푼 문제는 안 푼 문제 → 오래된 순
        weak.sort { lhs, rhs in
            let a = stats[lhs.id] ?? QuestionHistoryStats()
            let b = stats[rhs.id] ?? QuestionHistoryStats()
            return a.correctCount * b.totalCount < b.correctCount * a.totalCount
        }
        stale.sort { lhs, rhs in
            let a = stats[lhs.id]?.lastAnsweredAt ?? .distantPast
            let b = stats[rhs.id]?.lastAnsweredAt ?? .distantPast
            return a < b
        }

        let staleQuota = total / 2
        let weakQuota = total - staleQuota

        var chosen = Array(weak.prefix(weakQuota)) + Array(stale.prefix(staleQuota))
        let shortage = total - chosen.count
        if shortage > 0 {
            let leftovers = Array(weak.dropFirst(weakQuota)) + Array(stale.dropFirst(staleQuota)) + rest
            chosen += leftovers.prefix(shortage)
        }
        return shuffle(chosen)
    }

    func availableCount(
        category: QuizCategory?,
        difficulty: Difficulty,
        tags: Set<String>,
        questions: [Question]
    ) -> Int {
        candidates(category: category, difficulty: difficulty, tags: tags, questions: questions).count
    }

    // MARK: - 내부

    /// 카테고리·난이도·태그 조건에 맞는 후보. 카테고리가 nil이면 전체, 태그가 비어 있으면 전체 태그
    private func candidates(
        category: QuizCategory?,
        difficulty: Difficulty,
        tags: Set<String>,
        questions: [Question]
    ) -> [Question] {
        questions.filter { question in
            (category == nil || question.category == category)
                && question.difficulty == difficulty
                && (tags.isEmpty || !tags.isDisjoint(with: question.tags))
        }
    }

    /// 마지막 풀이가 오답이거나 정답률이 기준 미만이면 약한 문제
    private func isWeak(_ record: QuestionHistoryStats) -> Bool {
        guard record.totalCount > 0 else { return false }
        return !record.lastAnswerWasCorrect
            || SelectionCriteria.isWeak(correctCount: record.correctCount, totalCount: record.totalCount)
    }
}
