import SwiftData
import SwiftUI

@main struct MyApp: App {
    private let container: ModelContainer?
    private let services: AppServices?

    init() {
        do {
            let container = try ModelContainerFactory.make()
            self.container = container
            self.services = AppServices.make(context: container.mainContext)
        } catch {
            self.container = nil
            self.services = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container, let services {
                MainTabView()
                    .modelContainer(container)
                    .environment(\.services, services)
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
