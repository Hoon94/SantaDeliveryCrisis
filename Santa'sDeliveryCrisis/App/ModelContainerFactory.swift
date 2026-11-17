import SwiftData

/// `ModelContainer`를 한 곳에서 만든다. 다른 작업은 이 컨테이너를 주입받아 쓴다.
enum ModelContainerFactory {
    /// 앱에서 쓰는 모든 SwiftData 모델
    static let schema = Schema([
        Question.self,
        QuizSession.self,
        SessionAnswer.self,
        TreeRecord.self,
    ])

    /// 컨테이너를 만든다. 미리보기와 테스트에서는 `inMemory`를 true로 쓴다.
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
