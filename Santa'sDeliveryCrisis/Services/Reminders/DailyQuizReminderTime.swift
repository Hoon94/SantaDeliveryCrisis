/// 날짜·시간대와 분리해 저장하는 하루 중 학습 알림 시각.
nonisolated struct DailyQuizReminderTime: Equatable, Sendable {
    /// 기존 고정 알림과 같은 기본 시각인 오후 8시.
    static let defaultTime = DailyQuizReminderTime()

    /// 하루 중 시(0...23).
    let hour: Int
    /// 분(0...59).
    let minute: Int

    /// UserDefaults에 하나의 값으로 저장할 자정 이후 분 수.
    var minutesAfterMidnight: Int { hour * 60 + minute }

    /// 시·분을 지정한다. 범위를 벗어나면 기본 시각을 사용한다.
    init(hour: Int = 20, minute: Int = 0) {
        guard (0..<24).contains(hour), (0..<60).contains(minute) else {
            self = Self.defaultTime
            return
        }
        self.hour = hour
        self.minute = minute
    }
}
