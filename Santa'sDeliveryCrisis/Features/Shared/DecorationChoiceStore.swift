import Foundation

/// 출제 화면에서 사용자가 누른 장식(색)을 세션마다 기억해 두었다가, 결과 화면의 장식 획득 연출이 같은 색을 쓰게 한다.
///
/// 장식은 문제 카테고리와 연동하지 않으므로 세션 모델에는 어느 장식을 눌렀는지가 없다.
/// 이 값은 화면 색에만 쓰이고 출제, 채점, 보상에는 영향이 없다. 그래서 모델을 바꾸지 않고
/// `UserDefaults`에 세션 id별로 가볍게 저장한다(앱을 껐다 켜서 이어 풀어도 같은 색이 나온다).
/// 어떤 장식을 얻는지를 보상으로 정하게 되면 이 값은 `QuizSession`의 필드로 옮기는 것이 맞다.
enum DecorationChoiceStore {
    private static let key = "sessionDecorationChoices"
    /// 오래된 기록이 쌓이지 않도록 기억해 두는 세션 수의 상한
    private static let capacity = 40

    /// 세션을 시작한 장식을 기억한다. 같은 세션에 다시 부르면 덮어쓴다.
    static func save(_ category: QuizCategory, for sessionID: UUID, defaults: UserDefaults = .standard) {
        var entries = load(defaults: defaults)
        entries.removeAll { $0.session == sessionID.uuidString }
        entries.append((sessionID.uuidString, category.rawValue))
        if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
        defaults.set(entries.map { ["session": $0.session, "category": $0.category] }, forKey: key)
    }

    /// 세션을 시작한 장식. 기억이 없으면(예전 세션 등) nil이다.
    static func decoration(for sessionID: UUID, defaults: UserDefaults = .standard) -> QuizCategory? {
        load(defaults: defaults)
            .last { $0.session == sessionID.uuidString }
            .flatMap { QuizCategory(rawValue: $0.category) }
    }

    private static func load(defaults: UserDefaults) -> [(session: String, category: String)] {
        guard let raw = defaults.array(forKey: key) as? [[String: String]] else { return [] }
        return raw.compactMap { item in
            guard let session = item["session"], let category = item["category"] else { return nil }
            return (session, category)
        }
    }
}
