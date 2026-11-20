import Foundation
import Observation
import OSLog
import SwiftData
import UserNotifications

/// 완료 기록과 알림 권한을 확인하고 학습 알림만 예약·취소한다.
@MainActor @Observable
final class DailyQuizReminderManager: DailyQuizReminderManaging {
    /// 사용자가 저장한 학습 알림 사용 의사.
    private(set) var isEnabled: Bool
    /// 마지막으로 확인한 시스템 알림 권한.
    private(set) var authorization: DailyQuizReminderAuthorization = .notDetermined
    /// 설정 화면에 표시할 처리 오류.
    private(set) var errorMessage: String?

    /// 대기 중인 작업을 포함해 권한·예약 처리가 진행 중인지 여부.
    var isUpdating: Bool { operationCount > 0 }

    private let container: ModelContainer
    private let settings: SettingsStore
    private let center: UNUserNotificationCenter
    private let notificationDelegate = DailyQuizReminderNotificationDelegate()
    private var operationCount = 0
    private var preferenceRevision = 0
    @ObservationIgnored private var operationTail: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.KDT8.SantasDeliveryCrisis", category: "DailyQuizReminder")

    #if DEBUG
    private var hasScheduledDebugReminder = false
    #endif

    /// - Parameters:
    ///   - context: 완료 세션을 저장하는 실제 앱 컨텍스트.
    ///   - settings: 알림 사용 의사를 저장하는 설정.
    init(context: ModelContext, settings: SettingsStore) {
        container = context.container
        self.settings = settings
        isEnabled = settings.dailyQuizReminderEnabled
        center = .current()
        // 알림 센터의 delegate는 약한 참조이므로 서비스에서 수명을 유지한다.
        center.delegate = notificationDelegate
    }

    /// 사용자 선택을 먼저 저장하고, 오래된 비동기 작업이 다시 예약하지 못하게 한다.
    func setEnabled(_ enabled: Bool) async {
        #if DEBUG
        let wasEnabled = isEnabled
        #endif
        isEnabled = enabled
        settings.dailyQuizReminderEnabled = enabled
        preferenceRevision += 1
        #if DEBUG
        if !enabled || !wasEnabled { hasScheduledDebugReminder = false }
        #endif
        await enqueue(requestsPermission: enabled)
    }

    /// 앱 활성화 시 예약을 보충한다. 기존 개발용 타이머는 다시 시작하지 않는다.
    func refresh() async {
        await enqueue(requestsPermission: false)
    }

    /// 저장된 완료 기록으로 당일 예약을 취소한다. 실패해도 퀴즈 저장은 유지한다.
    func sessionCompleted() async {
        await enqueue(requestsPermission: false)
    }

    private func enqueue(requestsPermission: Bool) async {
        let revision = preferenceRevision
        let previous = operationTail
        operationCount += 1
        let task = Task { @MainActor [weak self] in
            await previous?.value
            guard let self else { return }
            defer { self.operationCount -= 1 }
            guard revision == self.preferenceRevision else { return }
            await self.synchronize(requestsPermission: requestsPermission, revision: revision)
        }
        operationTail = task
        await task.value
    }

    private func synchronize(requestsPermission: Bool, revision: Int) async {
        errorMessage = nil
        var notificationSettings = await center.notificationSettings()
        guard revision == preferenceRevision else { return }
        authorization = authorizationState(notificationSettings.authorizationStatus)

        if !isEnabled {
            await removeOwnedNotifications(includeDelivered: true)
            return
        }

        do {
            if requestsPermission, authorization == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
                notificationSettings = await center.notificationSettings()
                guard revision == preferenceRevision else { return }
                authorization = authorizationState(notificationSettings.authorizationStatus)
            }

            guard authorization == .allowed else {
                if requestsPermission {
                    isEnabled = false
                    settings.dailyQuizReminderEnabled = false
                    errorMessage = "기기 설정에서 알림을 허용해 주세요."
                }
                #if DEBUG
                hasScheduledDebugReminder = false
                #endif
                await removeOwnedNotifications(includeDelivered: false)
                return
            }

            let completedAt = try completedDates()
            let now = Date()
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            let completedToday = completedAt.contains {
                $0 <= now && calendar.isDate($0, inSameDayAs: now)
            }
            if completedToday {
                await removeDeliveredToday(now: now, calendar: calendar)
                guard revision == preferenceRevision else { return }
            }

            switch DailyQuizReminderConfiguration.mode {
            case .daily:
                try await scheduleDaily(completedAt: completedAt, now: now, revision: revision)
            #if DEBUG
            case .debugOneMinute:
                if completedToday {
                    await removeOwnedNotifications(includeDelivered: false)
                } else if !hasScheduledDebugReminder {
                    try await scheduleDebug(completedAt: completedAt, revision: revision)
                }
            #endif
            }
        } catch {
            guard revision == preferenceRevision else { return }
            if requestsPermission {
                isEnabled = false
                settings.dailyQuizReminderEnabled = false
            }
            #if DEBUG
            hasScheduledDebugReminder = false
            #endif
            errorMessage = "학습 알림을 설정하지 못했어요. 잠시 후 다시 시도해 주세요."
            Self.logger.error("학습 알림 동기화 실패: \(error.localizedDescription, privacy: .public)")
            // 기록 조회 실패도 미완료로 추정하지 않고, 잘못 알리지 않도록 예약을 정리한다.
            await removeOwnedNotifications(includeDelivered: false)
        }
    }

    private func completedDates() throws -> [Date] {
        // 별도 읽기 컨텍스트를 사용해 아직 저장되지 않은 변경을 알림 조건에서 제외한다.
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<QuizSession>()).compactMap { session in
            session.status == .completed ? session.finishedAt : nil
        }
    }

    private func scheduleDaily(completedAt: [Date], now: Date, revision: Int) async throws {
        let reminders = DailyQuizReminderSchedule().reminders(completedAt: completedAt, now: now, mode: .daily)
        let desiredIDs = Set(reminders.map(\.id))
        let pending = await center.pendingNotificationRequests()
        guard revision == preferenceRevision, isEnabled else { return }
        center.removePendingNotificationRequests(withIdentifiers: pending.filter {
            owns($0.identifier) && !desiredIDs.contains($0.identifier)
        }.map(\.identifier))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        for reminder in reminders {
            guard revision == preferenceRevision, isEnabled else { return }
            guard reminder.date > Date() else { continue }
            var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.date)
            parts.calendar = calendar
            parts.timeZone = calendar.timeZone
            let request = UNNotificationRequest(
                identifier: reminder.id,
                content: content(),
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            )
            try await center.add(request)
        }
    }

    #if DEBUG
    private func scheduleDebug(completedAt: [Date], revision: Int) async throws {
        await removeOwnedNotifications(includeDelivered: false)
        guard revision == preferenceRevision, isEnabled,
              let reminder = DailyQuizReminderSchedule().reminders(
                completedAt: completedAt, mode: .debugOneMinute
              ).first else { return }
        let request = UNNotificationRequest(
            identifier: reminder.id,
            content: content(),
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: DailyQuizReminderConfiguration.debugDelay, repeats: false
            )
        )
        try await center.add(request)
        guard revision == preferenceRevision, isEnabled else { return }
        hasScheduledDebugReminder = true
    }
    #endif

    private func content() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "오늘의 퀴즈를 풀어볼까요?"
        content.body = "오늘은 아직 완료한 퀴즈가 없어요. 한 판으로 학습 기록을 채워보세요."
        content.sound = .default
        return content
    }

    private func authorizationState(_ status: UNAuthorizationStatus) -> DailyQuizReminderAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized, .provisional, .ephemeral: .allowed
        case .denied: .denied
        @unknown default: .denied
        }
    }

    private func owns(_ identifier: String) -> Bool {
        identifier.hasPrefix(DailyQuizReminderConfiguration.identifierPrefix)
    }

    private func removeOwnedNotifications(includeDelivered: Bool) async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.filter { owns($0.identifier) }.map(\.identifier))
        if includeDelivered {
            let delivered = await center.deliveredNotifications()
            center.removeDeliveredNotifications(withIdentifiers: delivered.filter {
                owns($0.request.identifier)
            }.map { $0.request.identifier })
        }
    }

    private func removeDeliveredToday(now: Date, calendar: Calendar) async {
        let delivered = await center.deliveredNotifications()
        center.removeDeliveredNotifications(withIdentifiers: delivered.filter {
            owns($0.request.identifier) && calendar.isDate($0.date, inSameDayAs: now)
        }.map { $0.request.identifier })
    }
}
