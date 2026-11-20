import Foundation
import Observation

/// 설정 화면에 필요한 시스템 알림 권한 상태.
nonisolated enum DailyQuizReminderAuthorization: Equatable, Sendable {
    case notDetermined, allowed, denied
}

/// 학습 알림 설정과 예약을 관리하는 앱 서비스 계약.
@MainActor
protocol DailyQuizReminderManaging: AnyObject {
    /// 사용자가 저장한 알림 사용 의사. 시스템 권한과 별개다.
    var isEnabled: Bool { get }
    /// 저장된 사용자 알림 시각.
    var reminderTime: DailyQuizReminderTime { get }
    /// 마지막으로 확인한 시스템 권한 상태.
    var authorization: DailyQuizReminderAuthorization { get }
    /// 권한 요청 또는 예약 작업을 처리하고 있는지 여부.
    var isUpdating: Bool { get }
    /// 화면에 안내할 오류. 정상 처리 후에는 nil이다.
    var errorMessage: String? { get }
    /// 명시적인 사용자 조작으로 알림을 켜거나 끈다. 켤 때만 권한을 요청할 수 있다.
    func setEnabled(_ enabled: Bool) async
    /// 켜짐·권한을 다시 확인하고 시간을 저장한다. 재예약 실패 시에도 저장한 값은 유지한다.
    /// - Returns: 시간 저장을 수락했는지 여부. false이면 기존 시간이 유지된다.
    func updateTime(_ time: DailyQuizReminderTime) async -> Bool
    /// 앱 활성화 또는 재시도 시 권한·예약을 동기화한다. 권한 팝업을 자동으로 띄우지 않는다.
    func refresh() async
    /// 최초 세션 완료 저장 이후 당일 예약과 전달 알림을 정리한다.
    func sessionCompleted() async
}

/// 프리뷰용 알림 서비스. 실제 UserDefaults·시스템 권한·알림 예약에 접근하지 않는다.
@MainActor @Observable
final class MockDailyQuizReminderManager: DailyQuizReminderManaging {
    var isEnabled: Bool
    var reminderTime: DailyQuizReminderTime
    var authorization: DailyQuizReminderAuthorization
    var isUpdating: Bool
    var errorMessage: String?

    /// 표시할 프리뷰 상태를 지정한다.
    init(
        isEnabled: Bool = false,
        reminderTime: DailyQuizReminderTime = .defaultTime,
        authorization: DailyQuizReminderAuthorization = .notDetermined,
        isUpdating: Bool = false,
        errorMessage: String? = nil
    ) {
        self.isEnabled = isEnabled
        self.reminderTime = reminderTime
        self.authorization = authorization
        self.isUpdating = isUpdating
        self.errorMessage = errorMessage
    }

    /// 프리뷰 안의 표시 상태만 바꾼다.
    func setEnabled(_ enabled: Bool) async {
        errorMessage = nil
        if enabled, authorization == .denied {
            isEnabled = false
            errorMessage = "기기 설정에서 알림을 허용해 주세요."
        } else {
            isEnabled = enabled
            if enabled { authorization = .allowed }
        }
    }

    /// 프리뷰에서 시간 변경 정책만 반영하고 실제 예약은 하지 않는다.
    func updateTime(_ time: DailyQuizReminderTime) async -> Bool {
        guard isEnabled, authorization == .allowed else {
            errorMessage = "학습 알림을 켜고 기기 알림을 허용한 뒤 시간을 변경해 주세요."
            return false
        }
        reminderTime = time
        errorMessage = nil
        return true
    }

    /// 프리뷰에서는 외부 상태를 조회하지 않는다.
    func refresh() async {}

    /// 프리뷰에서는 실제 알림을 취소하지 않는다.
    func sessionCompleted() async {}
}
