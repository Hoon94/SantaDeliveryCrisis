import Foundation

/// 학습 알림 예약 범위와 개발용 테스트 방식을 정한다. 실제 시각은 사용자 설정을 따른다.
nonisolated enum DailyQuizReminderConfiguration {
    /// 사용할 알림 예약 방식. 테스트 방식은 Debug 빌드에만 존재한다.
    enum Mode: Equatable, Sendable {
        case daily
        #if DEBUG
        case debugOneMinute
        #endif
    }

    /// 오늘을 포함해 예약할 날짜 수.
    static let reservationDayCount = 7
    /// 이 기능의 예약·전달 알림만 찾아 정리할 식별자 접두사.
    static let identifierPrefix = "dailyQuizReminder."

    #if DEBUG
    /// true로 바꾸면 사용자 시각 대신 1분 뒤 테스트 알림을 사용한다.
    static let debugOneMinuteEnabled = false
    /// 유효한 테스트 예약을 시작한 시각부터 기다릴 초.
    static let debugDelay: TimeInterval = 60
    #endif

    /// 기본은 사용자 시각이며, Debug에서만 명시적으로 테스트 모드를 켤 수 있다.
    static var mode: Mode {
        #if DEBUG
        debugOneMinuteEnabled ? .debugOneMinute : .daily
        #else
        .daily
        #endif
    }
}
