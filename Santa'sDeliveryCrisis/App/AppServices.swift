import SwiftData
import SwiftUI

/// 앱 전체가 공유하는 서비스 묶음. 한 곳에서 조립하고 화면은 Environment로 주입받는다.
/// 실제 구현(작업 2 등)이 준비되면 이 조립 지점의 mock만 교체한다.
struct AppServices {
    let settings: SettingsStore
    let selector: QuestionSelecting
    let recommender: TaskRecommending
    let sessions: SessionManaging
    let trees: TreeManaging
    let feedback: FeedbackPlaying
    let media: MediaFileManaging
    let traceScenes: TraceSceneRegistry

    /// 실제 구현(출제, 추천, 세션, 트리, 미디어, 설정)과 아직 구현되지 않은 mock(피드백, 장면)을 조립한다.
    /// 세션과 트리는 같은 `ModelContext`를 써야 세션 완료와 장식 지급이 한 번의 저장으로 묶인다.
    static func make(context: ModelContext) -> AppServices {
        let settings = SettingsStore()
        let selector = QuestionSelector()
        let trees = TreeManager(context: context)
        let media = MediaFileManager(context: context)
        return AppServices(
            settings: settings,
            selector: selector,
            recommender: TaskRecommender(),
            sessions: SessionManager(
                context: context,
                selector: selector,
                trees: trees,
                settings: settings,
                media: media
            ),
            trees: trees,
            feedback: MockFeedbackPlayer(),
            media: media,
            traceScenes: MockTraceSceneRegistry()
        )
    }

    /// 미리보기용 전체 mock 묶음
    static let preview = AppServices(
        settings: SettingsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard),
        selector: MockQuestionSelector(),
        recommender: MockTaskRecommender(),
        sessions: MockSessionManager(),
        trees: MockTreeManager(),
        feedback: MockFeedbackPlayer(),
        media: MockMediaFileManager(),
        traceScenes: MockTraceSceneRegistry()
    )
}

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue = AppServices.preview
}

extension EnvironmentValues {
    /// 앱 서비스 묶음
    var services: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
