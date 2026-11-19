import SwiftData
import SwiftUI

/// 하단 탭 4개: 작업실 / 출제 / 기록 / 관리. 각 탭은 독립된 NavigationStack을 가진다.
struct MainTabView: View {
    /// 각 탭의 독립된 화면 이동 경로를 유지한다. 퀴즈는 출제 탭에서 진입한다.
    var body: some View {
        TabView {
            TabRoot(title: "작업실") { TaskHomeView() }
                .tabItem { Label("작업실", systemImage: "gift") }
            TabRoot(title: "출제") { SelectView() }
                .tabItem { Label("출제", systemImage: "tree") }
            TabRoot(title: "기록") { RecordsView() }
                .tabItem { Label("기록", systemImage: "chart.bar") }
            TabRoot(title: "관리") { ManageView() }
                .tabItem { Label("관리", systemImage: "list.bullet.rectangle") }
        }
        .tint(.appTint)
    }
}

/// 탭 루트를 NavigationStack으로 감싼다.
private struct TabRoot<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    if let container = try? ModelContainerFactory.make(inMemory: true) {
        MainTabView()
            .modelContainer(container)
            .environment(\.services, .preview)
    } else {
        ContentUnavailableView(
            "미리보기 저장소를 준비하지 못했어요", systemImage: "exclamationmark.triangle"
        )
    }
}
