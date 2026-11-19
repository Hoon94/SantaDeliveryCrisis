import SwiftData
import SwiftUI

/// 하단 탭 4개: 작업실 / 출제 / 기록 / 관리. 각 탭은 독립된 NavigationStack을 가진다.
struct MainTabView: View {
    private enum Tab: Hashable {
        case task, select, records, manage
    }

    @State private var selectedTab: Tab = .task
    /// 결과 화면의 장식이 작업실 트리로 날아가는 연출의 상태. 퀴즈, 작업실 트리, 가장 위 연출 층이 함께 쓴다.
    @State private var rewardFlight = RewardFlightCenter()

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
        // 장식이 날아가기 시작하면 트리가 있는 작업실 탭으로 옮긴다. 퀴즈 화면은 그 위에서 페이드로 닫힌다.
        .onChange(of: rewardFlight.flight?.id) { _, id in
            if id != nil { selectedTab = .task }
        }
        // 환경은 오버레이를 붙인 뒤에 넣어야 연출 층도 같은 상태 객체를 받는다.
        .overlay { RewardFlightOverlay() }
        .environment(\.rewardFlight, rewardFlight)
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
