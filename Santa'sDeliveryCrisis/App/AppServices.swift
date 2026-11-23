import SwiftData
import SwiftUI

/// 앱 전체가 공유하는 서비스 묶음. 한 곳에서 조립하고 화면은 Environment로 주입받는다.
struct AppServices {
    let settings: SettingsStore
    let selector: QuestionSelecting
    let recommender: TaskRecommending
    let sessions: SessionManaging
    let trees: TreeManaging
    let feedback: QuizFeedbackPlaying
    let media: MediaFileManaging
    /// 학습 알림의 권한·예약·설정 상태를 관리한다.
    let reminders: any DailyQuizReminderManaging

    /// 실제 서비스를 조립하고, 메모리 저장소에서는 시스템 알림 대신 프리뷰용 구현을 사용한다.
    /// 세션과 트리는 같은 `ModelContext`를 써야 세션 완료와 장식 지급이 한 번의 저장으로 묶인다.
    static func make(context: ModelContext) -> AppServices {
        let settings = SettingsStore()
        let selector = QuestionSelector()
        let trees = TreeManager(context: context)
        let media = MediaFileManager(context: context)
        let activityPublisher = QuizActivityPublisher(context: context)
        let reminders: any DailyQuizReminderManaging
        if context.container.configurations.contains(where: { !$0.isStoredInMemoryOnly }) {
            reminders = DailyQuizReminderManager(context: context, settings: settings)
        } else {
            reminders = MockDailyQuizReminderManager()
        }
        return AppServices(
            settings: settings,
            selector: selector,
            recommender: TaskRecommender(),
            sessions: SessionManager(
                context: context,
                selector: selector,
                trees: trees,
                settings: settings,
                media: media,
                onSessionCompleted: {
                    // 완료 저장 후 위젯을 갱신하고, 알림 정리는 비동기로 요청한다.
                    activityPublisher.refresh()
                    Task { await reminders.sessionCompleted() }
                }
            ),
            trees: trees,
            feedback: FeedbackPlayer(settings: settings),
            media: media,
            reminders: reminders
        )
    }

    /// 미리보기용 전체 mock 묶음
    static let preview: AppServices = {
        let trees = MockTreeManager()
        return AppServices(
            settings: SettingsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            selector: MockQuestionSelector(),
            recommender: MockTaskRecommender(),
            sessions: MockSessionManager(trees: trees),
            trees: trees,
            feedback: SilentFeedbackPlayer(),
            media: MockMediaFileManager(),
            reminders: MockDailyQuizReminderManager()
        )
    }()
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
