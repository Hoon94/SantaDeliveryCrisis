import Foundation

/// 월간 달력의 하루. 같은 날 여러 세션을 끝내도 완료 여부만 표시한다.
nonisolated struct QuizActivityDay: Identifiable, Equatable, Sendable {
    /// 표시 시간대에서 해당 날짜의 시작 시각.
    let date: Date
    /// 달력에 표시할 일자(1...31).
    let dayNumber: Int
    /// 해당 날짜에 완료한 세션이 하나 이상 있는지 여부.
    let isCompleted: Bool
    /// 계산 기준 시각이 속한 날짜인지 여부.
    let isToday: Bool
    /// 계산 기준 시각보다 뒤의 날짜인지 여부.
    let isFuture: Bool

    /// 날짜별 달력 항목을 구별하는 값.
    var id: Date { date }
}

/// 앱과 위젯이 공통으로 사용할 현재 월의 학습 표시 데이터.
nonisolated struct MonthlyQuizActivity: Equatable, Sendable {
    /// 그레고리력 기준 연도.
    let year: Int
    /// 그레고리력 기준 월(1...12).
    let month: Int
    /// 첫날 앞에 들어갈 빈 칸 수. 일요일 시작 기준으로 0...6이다.
    let leadingEmptyDayCount: Int
    /// 해당 월의 실제 날짜만 일자순으로 담은 목록.
    let days: [QuizActivityDay]

    /// 이번 달에 세션을 하나 이상 완료한 날짜 수.
    var completedDayCount: Int {
        days.filter(\.isCompleted).count
    }

    /// 오늘 완료한 세션이 하나 이상 있는지 여부.
    var isTodayCompleted: Bool {
        days.contains { $0.isToday && $0.isCompleted }
    }

    /// 일요일부터 토요일까지 7열로 그릴 달력. 월 앞뒤 빈 칸은 nil이다.
    var calendarCells: [QuizActivityDay?] {
        let occupiedCount = leadingEmptyDayCount + days.count
        let trailingEmptyDayCount = (7 - occupiedCount % 7) % 7
        return Array(repeating: nil, count: leadingEmptyDayCount)
            + days.map { Optional($0) }
            + Array(repeating: nil, count: trailingEmptyDayCount)
    }
}
