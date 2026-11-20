import Foundation
import SwiftData
import SwiftUI

@main struct MyApp: App {
    private let container: ModelContainer?
    private let services: AppServices?
    private let activityPublisher: QuizActivityPublisher?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let container = try ModelContainerFactory.make()
            self.container = container
            self.activityPublisher = QuizActivityPublisher(context: container.mainContext)
            // 첫 실행에 시드 문제를 넣는다. 이미 있는 문제는 건너뛰므로 매번 호출해도 된다.
            do {
                try SeedLoader.seed(into: container.mainContext)
            } catch {
                print("시드 문제 주입 실패: \(error.localizedDescription)")
            }
            let services = AppServices.make(context: container.mainContext)
            self.services = services
            // 쓰지 않는 미디어 파일을 앱 시작 때 한 번 정리한다. 실패해도 앱 실행에는 영향이 없다.
            try? services.media.cleanUnreferencedFiles()
        } catch {
            #if DEBUG
            let storeError = error as NSError
            print("앱 저장소 초기화 실패: \(storeError.domain), 코드 \(storeError.code), 상세 \(storeError.userInfo)")
            #endif
            self.container = nil
            self.services = nil
            self.activityPublisher = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container, let services {
                MainTabView()
                    .modelContainer(container)
                    .environment(\.services, services)
                    .onChange(of: scenePhase, initial: true) { _, phase in
                        if phase == .active {
                            activityPublisher?.refresh(forceReload: true)
                        }
                    }
            } else {
                ContentUnavailableView(
                    "데이터를 불러오지 못했어요",
                    systemImage: "exclamationmark.triangle",
                    description: Text("앱을 다시 실행해 주세요.")
                )
            }
        }
    }
}
