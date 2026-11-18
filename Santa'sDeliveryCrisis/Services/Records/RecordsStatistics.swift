import Foundation

/// 기록 대시보드의 집계 기간
enum RecordsPeriod: String, CaseIterable, Identifiable {
    case week, month

    var id: String { rawValue }

    /// 세그먼트에 표시하는 이름
    var displayName: String {
        switch self {
        case .week: "주간"
        case .month: "월간"
        }
    }
}

/// 하루 단위 집계 값. 막대 차트의 막대 하나가 된다.
struct DailyRecord: Identifiable, Equatable {
    /// 그날 0시
    let date: Date
    /// 그날 끝낸 세션에서 푼 문제 수
    let solvedCount: Int

    var id: Date { date }
}

/// 카테고리별 정답률
struct CategoryAccuracy: Identifiable, Equatable {
    let category: QuizCategory
    /// 0...100. 이 기간에 답한 문제가 없으면 nil
    let accuracyPercent: Int?
    /// 답한 문제 수
    let answeredCount: Int

    var id: QuizCategory { category }
}

/// 한 기간의 집계 결과
struct RecordsSummary: Equatable {
    /// 끝낸 세션 수
    let attemptCount: Int
    /// 세션별 정답률의 평균(소수점 버림). 끝낸 세션이 없으면 nil
    let averageScore: Int?
    /// 푼 문제 수
    let solvedCount: Int
    /// 기간 안의 모든 날(주간 7일, 월간은 그 달 일수). 세션이 없는 날도 포함
    let days: [DailyRecord]
    /// 4개 카테고리 전부. 정답률이 낮은 순이고, 동률이면 작업 순서가 앞선 쪽이 먼저.
    /// 이 기간에 답한 문제가 없는 카테고리(정답률 nil)는 맨 뒤에 둔다.
    let weakCategories: [CategoryAccuracy]

    /// 끝낸 세션이 하나도 없는지
    var isEmpty: Bool { attemptCount == 0 }
}

/// 세션 기록에서 기록 대시보드 값을 계산한다. 저장 없이 읽기만 한다.
///
/// 집계 기준
/// - 끝낸(`completed`) 세션만 센다. 그만둔 세션과 진행 중 세션은 제외한다.
/// - 기간은 세션이 끝난 시각(`finishedAt`) 기준이다. 주간은 월요일 시작, 월간은 그 달 1일 시작이다.
/// - 카테고리별 정답률은 답한 문제의 스냅샷 `category`로 계산한다.
struct RecordsStatistics {
    private let calendar: Calendar

    /// - Parameter calendar: 날짜 계산에 쓸 달력. 주 시작은 항상 월요일로 고정한다.
    init(calendar: Calendar = .current) {
        var fixed = calendar
        fixed.firstWeekday = 2
        fixed.minimumDaysInFirstWeek = 4
        self.calendar = fixed
    }

    /// `now`가 속한 주 또는 달의 집계를 계산한다.
    func summary(sessions: [QuizSession], period: RecordsPeriod, now: Date = Date()) -> RecordsSummary {
        guard let interval = interval(for: period, containing: now) else {
            return RecordsSummary(attemptCount: 0, averageScore: nil, solvedCount: 0, days: [], weakCategories: [])
        }
        let inPeriod = sessions.filter { session in
            guard session.status == .completed, let finishedAt = session.finishedAt else { return false }
            return interval.contains(finishedAt)
        }
        let scores = inPeriod.compactMap(score(of:))
        return RecordsSummary(
            attemptCount: inPeriod.count,
            averageScore: average(of: scores),
            solvedCount: inPeriod.reduce(0) { $0 + $1.answers.count },
            days: days(in: interval, sessions: inPeriod),
            weakCategories: weakCategories(in: inPeriod)
        )
    }

    /// 세션 하나의 정답률(0...100, 소수점 버림). 문제가 없는 세션은 nil.
    /// 결과 화면과 같은 값이 나오도록 정수 나눗셈으로 내림한다. 예: 7/9 → 77
    func score(of session: QuizSession) -> Int? {
        let total = session.questionIDs.count
        guard total > 0 else { return nil }
        let correct = session.answers.filter(\.isCorrect).count
        return correct * 100 / total
    }

    // MARK: - 내부 계산

    private func interval(for period: RecordsPeriod, containing date: Date) -> DateInterval? {
        switch period {
        case .week: calendar.dateInterval(of: .weekOfYear, for: date)
        case .month: calendar.dateInterval(of: .month, for: date)
        }
    }

    private func average(of values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / values.count
    }

    private func days(in interval: DateInterval, sessions: [QuizSession]) -> [DailyRecord] {
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.finishedAt ?? interval.start)
        }
        var result: [DailyRecord] = []
        var day = calendar.startOfDay(for: interval.start)
        while day < interval.end {
            let daySessions = sessionsByDay[day] ?? []
            result.append(
                DailyRecord(
                    date: day,
                    solvedCount: daySessions.reduce(0) { $0 + $1.answers.count }
                )
            )
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    private func weakCategories(in sessions: [QuizSession]) -> [CategoryAccuracy] {
        var answered: [QuizCategory: Int] = [:]
        var correct: [QuizCategory: Int] = [:]
        for session in sessions {
            let categoryByQuestion = Dictionary(
                session.questionSnapshots.map { ($0.questionID, $0.category) },
                uniquingKeysWith: { first, _ in first }
            )
            for answer in session.answers {
                guard let category = categoryByQuestion[answer.questionID] else { continue }
                answered[category, default: 0] += 1
                if answer.isCorrect { correct[category, default: 0] += 1 }
            }
        }
        return QuizCategory.allCases
            .map { category -> CategoryAccuracy in
                let count = answered[category] ?? 0
                guard count > 0 else {
                    return CategoryAccuracy(category: category, accuracyPercent: nil, answeredCount: 0)
                }
                let percent = (correct[category] ?? 0) * 100 / count
                return CategoryAccuracy(category: category, accuracyPercent: percent, answeredCount: count)
            }
            .enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element.accuracyPercent, rhs.element.accuracyPercent) {
                case let (left?, right?) where left != right: return left < right
                case (nil, _?): return false
                case (_?, nil): return true
                default: return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }
}
