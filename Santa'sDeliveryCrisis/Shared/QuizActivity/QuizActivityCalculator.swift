import Foundation

/// 완료 시각 목록을 월간 달력으로 바꾼다. 저장소·SwiftData·화면에 의존하지 않는다.
nonisolated struct QuizActivityCalculator: Sendable {
    private let timeZone: TimeZone

    /// - Parameter timeZone: 날짜를 나눌 시간대. 기본값은 기기의 시간대 변경을 따른다.
    init(timeZone: TimeZone = .autoupdatingCurrent) {
        self.timeZone = timeZone
    }

    /// 기준 시각이 속한 월의 학습 기록을 계산한다.
    ///
    /// 정답률과 보상은 판정하지 않는다. 호출하는 쪽에서 완료된 세션의
    /// `finishedAt`만 전달해야 하며, 진행 중·중단 세션은 전달하지 않는다.
    /// 완료 시각은 원본 그대로 받아 표시 시간대로 날짜를 다시 계산한다.
    /// - Parameters:
    ///   - completedAt: 완료된 세션의 완료 시각 목록. 같은 날 여러 항목이 있어도 하루로 센다.
    ///   - now: 오늘과 현재 월을 정할 기준 시각.
    /// - Returns: 월간 표시 데이터. 달력의 날짜 계산에 실패하면 nil을 반환한다.
    func month(completedAt: [Date], now: Date = Date()) -> MonthlyQuizActivity? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 1

        guard let interval = calendar.dateInterval(of: .month, for: now),
              let dayRange = calendar.range(of: .day, in: .month, for: now) else {
            return nil
        }
        let components = calendar.dateComponents([.year, .month], from: interval.start)
        guard let year = components.year, let month = components.month else { return nil }

        // 다음 달 시작 시각은 제외하고, 미래 시각의 기록도 완료로 세지 않는다.
        let completedDays = Set(completedAt.filter {
            $0 >= interval.start && $0 < interval.end && $0 <= now
        }.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: now)
        var days: [QuizActivityDay] = []
        for dayNumber in dayRange {
            // 초 단위 덧셈 대신 달력으로 날짜를 더해 서머타임이 있는 지역도 처리한다.
            guard let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: interval.start) else {
                return nil
            }
            let dayStart = calendar.startOfDay(for: date)
            days.append(QuizActivityDay(
                date: dayStart,
                dayNumber: dayNumber,
                isCompleted: completedDays.contains(dayStart),
                isToday: calendar.isDate(dayStart, inSameDayAs: now),
                isFuture: dayStart > today
            ))
        }

        return MonthlyQuizActivity(
            year: year,
            month: month,
            leadingEmptyDayCount: calendar.component(.weekday, from: interval.start) - calendar.firstWeekday,
            days: days
        )
    }
}
