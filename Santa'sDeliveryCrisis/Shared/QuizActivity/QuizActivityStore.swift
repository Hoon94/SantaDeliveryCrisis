import Foundation

/// 앱이 완료 시각을 쓰고 위젯이 읽는 App Group 공유 저장소.
/// 원본 세션은 앱에만 두고, 다시 만들 수 있는 완료 시각 목록만 공유한다.
nonisolated struct QuizActivityStore {
    /// 앱과 위젯 양쪽 entitlement에 등록한 공유 그룹.
    static let appGroupIdentifier = "group.com.KDT8.SantasDeliveryCrisis"
    /// 완료 후 갱신을 요청할 위젯 식별자.
    static let widgetKind = "QuizActivityWidget"

    /// 공유 저장소에 접근할 수 없거나 저장 형식이 올바르지 않은 상태.
    enum StoreError: Error {
        case unavailable, invalidData
    }

    private let defaults: UserDefaults?
    private let key = "quizActivity.completedAt.v1"

    /// 앱과 위젯이 같은 App Group의 UserDefaults를 사용하도록 준비한다.
    init() {
        defaults = UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    /// 완료 시각을 읽는다. nil은 아직 연결되지 않은 상태, 빈 배열은 연결 후 기록 없음이다.
    /// - Throws: 공유 저장소 접근 또는 저장 데이터 해석 오류.
    func load() throws -> [Date]? {
        guard let defaults else { throw StoreError.unavailable }
        guard let value = defaults.object(forKey: key) else { return nil }
        guard let data = value as? Data else { throw StoreError.invalidData }
        return try JSONDecoder().decode([Date].self, from: data)
    }

    /// 완료 시각을 한 번에 교체한다. 날짜로 변환하지 않아 표시 시간대 변경에 대응한다.
    /// - Parameter completedAt: 완료된 세션에서 읽은 완료 시각 목록.
    /// - Returns: 이전 저장 값과 달라 실제로 갱신 요청이 필요한지 여부.
    /// - Throws: 공유 저장소 접근 또는 데이터 인코딩 오류.
    @discardableResult
    func save(completedAt: [Date]) throws -> Bool {
        guard let defaults else { throw StoreError.unavailable }
        let data = try JSONEncoder().encode(Array(Set(completedAt)).sorted())
        guard defaults.data(forKey: key) != data else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
