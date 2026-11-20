import Foundation
import UserNotifications

/// 앱 사용 중 학습 알림의 배너와 소리를 생략한다. 알림 탭의 기본 앱 열기 동작은 유지한다.
nonisolated final class DailyQuizReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// 학습 알림만 숨기며, 다른 알림은 일반 배너와 소리를 사용한다.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        let isStudyReminder = notification.request.identifier.hasPrefix(
            DailyQuizReminderConfiguration.identifierPrefix
        )
        completionHandler(isStudyReminder ? [] : [.banner, .sound])
    }
}
