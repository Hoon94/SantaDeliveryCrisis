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
    /// 마지막으로 저장한 사용자 알림 시각.
    private(set) var reminderTime: DailyQuizReminderTime
    /// 마지막으로 확인한 시스템 알림 권한.
    private(set) var authorization: DailyQuizReminderAuthorization = .notDetermined
    /// 설정 화면에 표시할 처리 오류.
    private(set) var errorMessage: String?

    /// 대기 중인 작업을 포함해 권한·예약 처리가 진행 중인지 여부.
    var isUpdating: Bool { operationCount > 0 }

    private let container: ModelContainer
    private let settings: SettingsStore
    private let center: UNUserNotificationCenter
    private let history: DailyQuizReminderHistory
    private let notificationDelegate = DailyQuizReminderNotificationDelegate()
    private var operationCount = 0
    private var preferenceRevision = 0
    @ObservationIgnored private var operationTail: Task<Bool, Never>?
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
        history = DailyQuizReminderHistory(settings: settings)
        isEnabled = settings.dailyQuizReminderEnabled
        reminderTime = settings.dailyQuizReminderTime
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
        _ = await enqueue(requestsPermission: enabled)
    }

    /// 시간 저장과 재예약을 순차 처리한다. 시스템 권한 팝업은 띄우지 않는다.
    /// - Returns: 시간 저장 여부. 저장 후 예약에 실패해도 true이며 오류 상태로 재시도할 수 있다.
    func updateTime(_ time: DailyQuizReminderTime) async -> Bool {
        preferenceRevision += 1
        return await enqueue(requestsPermission: false, updatedTime: time)
    }

    /// 앱 활성화 시 예약을 보충한다. 기존 개발용 타이머는 다시 시작하지 않는다.
    func refresh() async {
        _ = await enqueue(requestsPermission: false)
    }

    /// 저장된 완료 기록으로 당일 예약을 취소한다. 실패해도 퀴즈 저장은 유지한다.
    func sessionCompleted() async {
        _ = await enqueue(requestsPermission: false)
    }

    private func enqueue(requestsPermission: Bool, updatedTime: DailyQuizReminderTime? = nil) async -> Bool {
        let revision = preferenceRevision
        let previous = operationTail
        operationCount += 1
        let task = Task { @MainActor [weak self] in
            _ = await previous?.value
            guard let self else { return false }
            defer { self.operationCount -= 1 }
            guard revision == self.preferenceRevision else { return false }
            return await self.synchronize(
                requestsPermission: requestsPermission, revision: revision, updatedTime: updatedTime
            )
        }
        operationTail = task
        return await task.value
    }

    private func synchronize(
        requestsPermission: Bool, revision: Int, updatedTime: DailyQuizReminderTime?
    ) async -> Bool {
        errorMessage = nil
        var notificationSettings = await center.notificationSettings()
        guard revision == preferenceRevision else { return false }
        authorization = authorizationState(notificationSettings.authorizationStatus)

        if updatedTime != nil, !isEnabled || authorization != .allowed {
            errorMessage = "학습 알림을 켜고 기기 알림을 허용한 뒤 시간을 변경해 주세요."
            await removeOwnedNotifications(includeDelivered: false)
            return false
        }

        if !isEnabled {
            await removeOwnedNotifications(includeDelivered: true)
            return false
        }

        var didSaveTime = false
        do {
            if requestsPermission, authorization == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
                notificationSettings = await center.notificationSettings()
                guard revision == preferenceRevision else { return false }
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
                return false
            }

            if let updatedTime {
                reminderTime = updatedTime
                settings.dailyQuizReminderTime = updatedTime
                didSaveTime = true
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
                guard revision == preferenceRevision else { return didSaveTime }
            }

            switch DailyQuizReminderConfiguration.mode {
            case .daily:
                try await scheduleDaily(completedAt: completedAt, revision: revision)
            #if DEBUG
            case .debugOneMinute:
                if completedToday {
                    await removeOwnedNotifications(includeDelivered: false)
                } else if !hasScheduledDebugReminder {
                    try await scheduleDebug(completedAt: completedAt, revision: revision)
                }
            #endif
            }
            return true
        } catch {
            guard revision == preferenceRevision else { return didSaveTime }
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
            return didSaveTime
        }
    }

    private func completedDates() throws -> [Date] {
        // 별도 읽기 컨텍스트를 사용해 아직 저장되지 않은 변경을 알림 조건에서 제외한다.
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<QuizSession>()).compactMap { session in
            session.status == .completed ? session.finishedAt : nil
        }
    }

    private func scheduleDaily(completedAt: [Date], revision: Int) async throws {
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        guard revision == preferenceRevision, isEnabled else { return }
        let now = Date()
        history.refresh(knownReservations: calendarReservations(from: pending + delivered.map(\.request)), now: now)
        let reminders = DailyQuizReminderSchedule().reminders(
            completedAt: completedAt, time: reminderTime, now: now, mode: .daily
        ).filter { !history.isConsumed($0.id) }
        let desiredIDs = Set(reminders.map(\.id))
        let cancellationTime = Date()
        center.removePendingNotificationRequests(withIdentifiers: pending.filter {
            owns($0.identifier) && !desiredIDs.contains($0.identifier)
        }.map(\.identifier))
        history.keepFutureReservations(desiredIDs, now: cancellationTime)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        for reminder in reminders {
            guard revision == preferenceRevision, isEnabled else { return }
            history.refresh()
            guard reminder.date > Date(), !history.isConsumed(reminder.id) else { continue }
            var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.date)
            parts.calendar = calendar
            parts.timeZone = calendar.timeZone
            let request = UNNotificationRequest(
                identifier: reminder.id,
                content: content(),
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            )
            try await center.add(request)
            if !history.record(reminder) {
                // 시스템에 등록하는 사이 이전 시각이 지난 경우에도 추가 알림을 막는다.
                center.removePendingNotificationRequests(withIdentifiers: [reminder.id])
            }
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
        let delivered = await center.deliveredNotifications()
        let cancellationTime = Date()
        history.refresh(
            knownReservations: calendarReservations(from: pending + delivered.map(\.request)), now: cancellationTime
        )
        center.removePendingNotificationRequests(withIdentifiers: pending.filter { owns($0.identifier) }.map(\.identifier))
        history.keepFutureReservations([], now: cancellationTime)
        if includeDelivered {
            center.removeDeliveredNotifications(withIdentifiers: delivered.filter {
                owns($0.request.identifier)
            }.map { $0.request.identifier })
        }
    }

    private func removeDeliveredToday(now: Date, calendar: Calendar) async {
        let delivered = await center.deliveredNotifications()
        history.refresh(knownReservations: calendarReservations(from: delivered.map(\.request)), now: now)
        center.removeDeliveredNotifications(withIdentifiers: delivered.filter {
            owns($0.request.identifier) && calendar.isDate($0.date, inSameDayAs: now)
        }.map { $0.request.identifier })
    }

    private func calendarReservations(from requests: [UNNotificationRequest]) -> [String: Date] {
        var reservations: [String: Date] = [:]
        for request in requests where owns(request.identifier) {
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { continue }
            let parts = trigger.dateComponents
            guard parts.year != nil, parts.month != nil, parts.day != nil,
                  parts.hour != nil, parts.minute != nil else { continue }
            var calendar = parts.calendar ?? Calendar(identifier: .gregorian)
            if let timeZone = parts.timeZone { calendar.timeZone = timeZone }
            if let date = calendar.date(from: parts) { reservations[request.identifier] = date }
        }
        return reservations
    }
}
