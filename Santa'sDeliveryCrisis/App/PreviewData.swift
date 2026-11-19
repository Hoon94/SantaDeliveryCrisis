#if DEBUG
import SwiftData
import SwiftUI

/// 화면 미리보기(`#Preview`)에서 **실제 서비스**와 시드 문제를 쓰기 위한 도우미.
/// 가짜(`AppServices.preview`) 대신 실제 출제·세션·트리 로직으로 화면을 확인할 수 있다.
/// 메모리에만 저장하므로 실제 앱 데이터에 영향이 없다. 디버그 빌드에서만 컴파일된다.
///
/// 사용 예:
/// ```swift
/// #Preview {
///     let preview = PreviewData.make()
///     TaskHomeView(onSelectQuestions: {})
///         .modelContainer(preview.container)
///         .environment(\.services, preview.services)
/// }
/// ```
enum PreviewData {
    /// 미리보기용 컨테이너와 서비스 묶음
    struct Environment {
        let container: ModelContainer
        let services: AppServices
    }

    /// 메모리 저장소와 실제 서비스를 만든다.
    /// - Parameter seeded: true면 시드 문제 전체를 넣는다. 빈 상태 화면을 볼 때는 false
    /// - Note: 메모리 저장소 생성이 실패하는 일은 사실상 없다. 실패하면 미리보기 설정 오류이므로 바로 중단한다.
    @MainActor
    static func make(seeded: Bool = true) -> Environment {
        do {
            let container = try ModelContainerFactory.make(inMemory: true)
            if seeded {
                try SeedLoader.seed(into: container.mainContext)
            }
            return Environment(container: container, services: AppServices.make(context: container.mainContext))
        } catch {
            preconditionFailure("미리보기 환경을 만들지 못했습니다: \(error)")
        }
    }
}
#endif
