import Foundation

/// 시스템에 예약할 학습 알림 하나의 식별자와 전달 희망 시각.
nonisolated struct DailyQuizReminderDate: Identifiable, Equatable, Sendable {
    /// 날짜별 예약 또는 Debug 테스트 예약을 구분하는 식별자.
    let id: String
    /// 알림을 전달할 시각. 실제 전달은 시스템 설정의 영향을 받는다.
    let date: Date

    /// 시간 변경 전후에도 같은 날짜는 같은 예약으로 식별한다.
    static func identifier(for date: Date, calendar: Calendar) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return DailyQuizReminderConfiguration.identifierPrefix
            + String(format: "%04d-%02d-%02d", year, month, day)
    }
}

/// 완료 기록과 현재 시각으로 예약할 알림을 계산한다. 권한 요청과 실제 예약은 하지 않는다.
nonisolated struct DailyQuizReminderSchedule: Sendable {
    private let timeZone: TimeZone

    /// - Parameter timeZone: 하루를 구분할 시간대. 기본값은 기기의 시간대 변경을 따른다.
    init(timeZone: TimeZone = .autoupdatingCurrent) {
        self.timeZone = timeZone
    }

    /// 오늘부터 7일의 실제 알림 또는 1분 뒤 테스트 알림을 계산한다.
    ///
    /// 호출하는 서비스가 완료된 세션의 `finishedAt`만 전달해야 한다.
    /// 테스트 모드의 앱 실행별 한 번 예약과 기존 타이머 유지는 서비스가 담당한다.
    /// - Parameters:
    ///   - completedAt: 완료한 세션의 시각 목록. 정답률·보상 여부와 관계없이 전달한다.
    ///   - time: 기기의 현지 시각으로 적용할 시·분. 테스트 모드에서는 사용하지 않는다.
    ///   - now: 예약 계산 기준 시각. 실제 예약 서비스는 권한 확인 뒤의 시각을 사용한다.
    ///   - mode: 예약 방식. 기본값은 빌드 종류와 개발용 설정에 따라 결정한다.
    /// - Returns: 완료한 날과 이미 지난 시각을 제외한 예약 목록.
    func reminders(
        completedAt: [Date],
        time: DailyQuizReminderTime = .defaultTime,
        now: Date = Date(),
        mode: DailyQuizReminderConfiguration.Mode = DailyQuizReminderConfiguration.mode
    ) -> [DailyQuizReminderDate] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: now)
        let completedDays = Set(completedAt.filter { $0 <= now }.map {
            calendar.startOfDay(for: $0)
        })

        switch mode {
        case .daily:
            return (0..<DailyQuizReminderConfiguration.reservationDayCount).compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                      !completedDays.contains(calendar.startOfDay(for: day)),
                      let date = calendar.date(
                        bySettingHour: time.hour,
                        minute: time.minute,
                        second: 0,
                        of: day
                      ),
                      calendar.isDate(date, inSameDayAs: day), date > now else {
                    return nil
                }
                return DailyQuizReminderDate(
                    id: DailyQuizReminderDate.identifier(for: day, calendar: calendar),
                    date: date
                )
            }
        #if DEBUG
        case .debugOneMinute:
            guard !completedDays.contains(today) else { return [] }
            return [DailyQuizReminderDate(
                id: DailyQuizReminderConfiguration.identifierPrefix + "debug",
                date: now.addingTimeInterval(DailyQuizReminderConfiguration.debugDelay)
            )]
        #endif
        }
    }
}
