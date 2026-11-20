import Foundation

/// 사용자 시간 선택 없이 개발자가 정하는 학습 알림 시각과 예약 범위.
nonisolated enum DailyQuizReminderConfiguration {
    /// 사용할 알림 예약 방식. 테스트 방식은 Debug 빌드에만 존재한다.
    enum Mode: Equatable, Sendable {
        case daily
        #if DEBUG
        case debugOneMinute
        #endif
    }

    /// 실제 알림 시각: 기기의 현지 시각 오후 8시.
    static let hour = 20
    /// 실제 알림 시각의 분.
    static let minute = 0
    /// 오늘을 포함해 예약할 날짜 수.
    static let reservationDayCount = 7
    /// 이 기능의 예약·전달 알림만 찾아 정리할 식별자 접두사.
    static let identifierPrefix = "dailyQuizReminder."

    #if DEBUG
    /// false로 바꾸면 Debug에서도 실제 오후 8시 예약을 확인할 수 있다.
    static let debugOneMinuteEnabled = true
    /// 유효한 테스트 예약을 시작한 시각부터 기다릴 초.
    static let debugDelay: TimeInterval = 60
    #endif

    /// Release는 항상 실제 시각을 사용하고 Debug만 개발용 설정을 따른다.
    static var mode: Mode {
        #if DEBUG
        debugOneMinuteEnabled ? .debugOneMinute : .daily
        #else
        .daily
        #endif
    }
}
