import Foundation

/// 기존 예약 시각이 지난 날의 추가 예약을 막는 이력. 실제 알림 표시·읽음 여부를 판정하지 않는다.
@MainActor
final class DailyQuizReminderHistory {
    private let settings: SettingsStore
    private let legacyWasEnabled: Bool
    private let legacyTime: DailyQuizReminderTime

    /// - Parameter settings: 예약 시각과 추가 예약 제한 날짜를 저장할 앱 설정.
    init(settings: SettingsStore) {
        self.settings = settings
        legacyWasEnabled = settings.dailyQuizReminderEnabled
        legacyTime = settings.dailyQuizReminderTime
    }

    /// 기존 예약·전달 알림을 반영하고 예약 시각이 지난 날짜의 추가 예약을 제한한다.
    /// 날짜가 바뀌면 과거 일주일과 현재 예약 범위의 이력만 유지한다.
    func refresh(knownReservations: [String: Date] = [:], now: Date = Date()) {
        var reservations = settings.dailyQuizReminderReservations
        var consumed = settings.dailyQuizReminderConsumedDays
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        if !settings.dailyQuizReminderHistoryInitialized {
            // 이전 버전에는 배너를 지운 뒤 남는 이력이 없다. 기존 사용 시각이 지났다면
            // 실제 전달 여부를 추정해 재발송하지 않고, 그날의 추가 예약을 제한한다.
            if legacyWasEnabled, DailyQuizReminderConfiguration.mode == .daily,
               let previousDate = calendar.date(
                bySettingHour: legacyTime.hour, minute: legacyTime.minute, second: 0, of: now
               ), previousDate <= now {
                consumed.insert(DailyQuizReminderDate.identifier(for: now, calendar: calendar))
            }
        }
        // 변경 전 시각을 먼저 확인해 더 늦은 시각으로 바꿔도 당일분을 재등록하지 않는다.
        consumed.formUnion(reservations.filter { $0.value <= now }.keys)
        reservations.merge(knownReservations) { _, incoming in incoming }
        consumed.formUnion(reservations.filter { $0.value <= now }.keys)

        let span = DailyQuizReminderConfiguration.reservationDayCount
        let retainedIDs = Set((-span..<span).compactMap { offset -> String? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            return DailyQuizReminderDate.identifier(for: date, calendar: calendar)
        })
        settings.dailyQuizReminderReservations = reservations.filter { retainedIDs.contains($0.key) }
        settings.dailyQuizReminderConsumedDays = consumed.intersection(retainedIDs)
        settings.dailyQuizReminderHistoryInitialized = true
    }

    /// 해당 날짜의 기존 예약 시각이 지나 추가 예약을 막아야 하는지 확인한다.
    func isConsumed(_ identifier: String) -> Bool {
        settings.dailyQuizReminderConsumedDays.contains(identifier)
    }

    /// 등록에 성공한 예약을 기록한다. 이전 예약 시각이 이미 지났다면 false를 반환한다.
    @discardableResult
    func record(_ reminder: DailyQuizReminderDate) -> Bool {
        refresh()
        guard !isConsumed(reminder.id) else { return false }
        var reservations = settings.dailyQuizReminderReservations
        reservations[reminder.id] = reminder.date
        settings.dailyQuizReminderReservations = reservations
        refresh()
        return !isConsumed(reminder.id)
    }

    /// 취소한 미래 예약의 이력을 지운다. 시각이 이미 지난 날의 추가 예약 제한은 유지한다.
    func keepFutureReservations(_ identifiers: Set<String>, now: Date = Date()) {
        refresh(now: now)
        settings.dailyQuizReminderReservations = settings.dailyQuizReminderReservations.filter {
            $0.value <= now || identifiers.contains($0.key)
        }
    }
}
