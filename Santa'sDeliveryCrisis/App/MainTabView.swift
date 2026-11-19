import SwiftData
import SwiftUI

/// 하단 탭 4개: 작업실 / 출제 / 기록 / 관리. 각 탭은 독립된 NavigationStack을 가진다.
struct MainTabView: View {
    private enum Tab: Hashable {
        case task, select, records, manage
    }

    @State private var selectedTab: Tab = .task

    /// 선택 상태를 공유하며 각 탭의 독립된 화면 이동 경로를 유지한다.
    var body: some View {
        TabView(selection: $selectedTab) {
            TaskHomeNavigationView(onSelectQuestions: { selectedTab = .select })
                .tabItem { Label("작업실", systemImage: "gift") }
                .tag(Tab.task)
            TabRoot(title: "출제") { SelectView() }
                .tabItem { Label("출제", systemImage: "tree") }
                .tag(Tab.select)
            TabRoot(title: "기록") { RecordsView() }
                .tabItem { Label("기록", systemImage: "chart.bar") }
                .tag(Tab.records)
            TabRoot(title: "관리") { ManageView() }
                .tabItem { Label("관리", systemImage: "list.bullet.rectangle") }
                .tag(Tab.manage)
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
