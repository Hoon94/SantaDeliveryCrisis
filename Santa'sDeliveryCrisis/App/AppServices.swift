import SwiftData
import SwiftUI

/// 앱 전체가 공유하는 서비스 묶음. 한 곳에서 조립하고 화면은 Environment로 주입받는다.
/// 실제 구현(작업 2 등)이 준비되면 이 조립 지점의 mock만 교체한다.
struct AppServices {
    let settings: SettingsStore
    let selector: QuestionSelecting
    let sessions: SessionManaging
    let trees: TreeManaging
    let feedback: FeedbackPlaying
    let media: MediaFileManaging
    let traceScenes: TraceSceneRegistry

    /// 실제 저장소(`MediaFileManager`, `SettingsStore`)와 아직 구현되지 않은 mock을 조립한다.
    static func make(context: ModelContext) -> AppServices {
        AppServices(
            settings: SettingsStore(),
            selector: MockQuestionSelector(),
            sessions: MockSessionManager(),
            trees: MockTreeManager(),
            feedback: MockFeedbackPlayer(),
            media: MediaFileManager(context: context),
            traceScenes: MockTraceSceneRegistry()
        )
    }

    /// 미리보기용 전체 mock 묶음
    static let preview = AppServices(
        settings: SettingsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard),
        selector: MockQuestionSelector(),
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
