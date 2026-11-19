import SwiftData
import SwiftUI

/// 하단 탭 4개: 작업실 / 출제 / 기록 / 관리. 각 탭은 독립된 NavigationStack을 가진다.
struct MainTabView: View {
    private enum Tab: Hashable {
        case task, select, records, manage
    }

    @State private var selectedTab: Tab = .task
    @State private var setupRequestID: UUID?
    @State private var activeQuizSession: QuizSession?

    /// 탭별 이동 경로를 유지하고 작업실의 새 퀴즈 요청을 출제 탭으로 전달한다.
    var body: some View {
        TabView(selection: $selectedTab) {
            TabRoot(title: "작업실") {
                TaskHomeView {
                    setupRequestID = UUID()
                    selectedTab = .select
                }
            }
                .tabItem { Label("작업실", systemImage: "gift") }
                .tag(Tab.task)
            TabRoot(title: "출제") {
                SelectView(activeQuizSession: $activeQuizSession, setupRequestID: setupRequestID)
            }
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
        .fullScreenCover(item: $activeQuizSession) { session in
            QuizEntryPresentation(session: session, onWillClose: prepareWorkshopReturn)
                .presentationBackground(.clear)
        }
    }

    /// 퀴즈가 화면을 덮고 있을 때 복귀 탭을 바꿔 출제 화면이 잠깐 보이는 것을 방지한다.
    private func prepareWorkshopReturn() {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            selectedTab = .task
        }
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

#if DEBUG
/// 실제 세션 서비스를 사용해 탭 전환과 퀴즈 종료 후 복귀를 확인하는 프리뷰.
@ViewBuilder
private func quizNavigationPreview(existingSession: Bool) -> some View {
    let questions = QuizCategory.allCases.flatMap { category in
        Difficulty.allCases.flatMap { difficulty in
            TaskSelectPreviewData.questions(category: category, difficulty: difficulty, count: 15)
        }
    }
    let sessions = existingSession ? [TaskSelectPreviewData.session(
        questions: Array(questions.filter { $0.category == .swiftSyntax && $0.difficulty == .normal }.prefix(5)),
        category: .swiftSyntax, difficulty: .normal, answered: 2
    )] : []

    if let preview = try? TaskSelectPreviewData.environment(questions: questions, sessions: sessions) {
        MainTabView()
            .modelContainer(preview.container)
            .environment(\.services, preview.services)
    } else {
        ContentUnavailableView("미리보기 데이터를 준비하지 못했어요", systemImage: "exclamationmark.triangle")
    }
}

#Preview("탭 흐름 · 새 퀴즈 시작과 작업실 복귀") {
    quizNavigationPreview(existingSession: false)
}

#Preview("탭 흐름 · 진행 중 세션 복원과 작업실 복귀") {
    quizNavigationPreview(existingSession: true)
}
#endif
