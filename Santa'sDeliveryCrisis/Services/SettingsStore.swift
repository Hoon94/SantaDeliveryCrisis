import Foundation

/// 설정 키와 기본값. 서비스는 `@AppStorage`를 직접 읽지 않고 이 저장소를 주입받는다.
/// 설정 화면의 `@AppStorage`도 같은 키(`SettingsStore.Key`)를 쓴다.
final class SettingsStore {
    /// UserDefaults 키
    enum Key {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let passThresholdPercent = "passThresholdPercent"
        static let soundEnabled = "soundEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        /// 고정 시각 학습 알림 사용 여부.
        static let dailyQuizReminderEnabled = "dailyQuizReminderEnabled"
    }

    /// 기본값
    enum Default {
        static let hasLaunchedBefore = false
        static let passThresholdPercent = 80
        static let soundEnabled = true
        static let hapticsEnabled = true
        /// 사용자가 직접 켜기 전에는 알림을 예약하지 않는다.
        static let dailyQuizReminderEnabled = false
    }

    /// 정답률 기준으로 허용하는 값 (50~100, 10 단위)
    static let passThresholdRange: ClosedRange<Int> = 50...100
    static let passThresholdStep = 10

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 첫 실행 여부 (시드 주입과 온보딩 판단)
    var hasLaunchedBefore: Bool {
        get { bool(Key.hasLaunchedBefore, default: Default.hasLaunchedBefore) }
        set { defaults.set(newValue, forKey: Key.hasLaunchedBefore) }
    }

    /// 보상 받는 정답률 기준. 허용 범위를 벗어난 값은 기본값으로 되돌려 읽는다.
    var passThresholdPercent: Int {
        get {
            guard defaults.object(forKey: Key.passThresholdPercent) != nil else {
                return Default.passThresholdPercent
            }
            let value = defaults.integer(forKey: Key.passThresholdPercent)
            let isValid = Self.passThresholdRange.contains(value) && value % Self.passThresholdStep == 0
            return isValid ? value : Default.passThresholdPercent
        }
        set { defaults.set(newValue, forKey: Key.passThresholdPercent) }
    }

    /// 효과음
    var soundEnabled: Bool {
        get { bool(Key.soundEnabled, default: Default.soundEnabled) }
        set { defaults.set(newValue, forKey: Key.soundEnabled) }
    }

    /// 진동
    var hapticsEnabled: Bool {
        get { bool(Key.hapticsEnabled, default: Default.hapticsEnabled) }
        set { defaults.set(newValue, forKey: Key.hapticsEnabled) }
    }

    /// 매일 학습 알림 사용 의사. 시스템의 알림 권한과는 별도로 저장한다.
    var dailyQuizReminderEnabled: Bool {
        get { bool(Key.dailyQuizReminderEnabled, default: Default.dailyQuizReminderEnabled) }
        set { defaults.set(newValue, forKey: Key.dailyQuizReminderEnabled) }
    }

    private func bool(_ key: String, default fallback: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.bool(forKey: key)
    }
}
