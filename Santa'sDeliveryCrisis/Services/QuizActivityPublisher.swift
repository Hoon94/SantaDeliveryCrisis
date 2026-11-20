import Foundation
import OSLog
import SwiftData
import WidgetKit

/// 앱에 저장된 완료 세션을 위젯용 공유 기록으로 내보낸다.
/// 동기화 실패는 퀴즈 저장 결과에 영향을 주지 않고 다음 앱 활성화 때 다시 시도한다.
@MainActor
final class QuizActivityPublisher {
    private let container: ModelContainer
    private static let logger = Logger(subsystem: "com.KDT8.SantasDeliveryCrisis", category: "QuizActivity")

    /// - Parameter context: 실제 세션을 저장하는 앱 컨텍스트. 같은 컨테이너에서 저장된 값만 읽는다.
    init(context: ModelContext) {
        container = context.container
    }

    /// 완료 시각을 다시 집계하고 변경된 기록이 있으면 위젯 갱신을 요청한다.
    /// 메모리 전용 프리뷰는 공유 기록을 쓰지 않으며, 조회 실패 시 기존 공유 기록을 유지한다.
    /// - Parameter forceReload: 기록이 같아도 시간대·날짜 변경을 반영할 갱신을 요청할지 여부.
    func refresh(forceReload: Bool = false) {
        guard container.configurations.contains(where: { !$0.isStoredInMemoryOnly }) else { return }

        do {
            // 별도 읽기 컨텍스트를 사용해 아직 저장되지 않은 변경을 내보내지 않는다.
            let context = ModelContext(container)
            let sessions = try context.fetch(FetchDescriptor<QuizSession>())
            let completedAt = sessions.compactMap { session -> Date? in
                guard session.status == .completed else { return nil }
                return session.finishedAt
            }
            let changed = try QuizActivityStore().save(completedAt: completedAt)
            if changed || forceReload {
                WidgetCenter.shared.reloadTimelines(ofKind: QuizActivityStore.widgetKind)
            }
        } catch {
            Self.logger.error("위젯 학습 기록 동기화 실패: \(error.localizedDescription, privacy: .public)")
        }
    }
}
