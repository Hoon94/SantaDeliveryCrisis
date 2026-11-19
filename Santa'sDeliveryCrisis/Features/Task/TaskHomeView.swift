import SwiftData
import SwiftUI

/// 작업실의 이동 경로와 탭 바 표시를 한곳에서 관리한다.
struct TaskHomeNavigationView: View {
    @State private var sessionPath: [UUID] = []

    /// 오늘의 출제 버튼에서 출제 탭으로 이동하는 동작.
    let onSelectQuestions: () -> Void

    /// 작업실에서는 탭 바를 표시하고 세션으로 이동한 동안에는 숨긴다.
    var body: some View {
        NavigationStack(path: $sessionPath) {
            TaskHomeView(onSelectQuestions: onSelectQuestions)
                .navigationTitle("작업실")
                .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar(sessionPath.isEmpty ? .visible : .hidden, for: .tabBar)
    }
}

/// 현재 트리와 남은 장식을 보여 주는 작업실 화면.
struct TaskHomeView: View {
    @Environment(\.services) private var services
    @Query private var questions: [Question]
    @Query private var history: [QuizSession]
    /// 현재 트리는 서비스와 동일하게 가장 먼저 시작한 기록을 사용한다.
    @Query(
        filter: #Predicate<TreeRecord> { $0.completedAt == nil },
        sort: \TreeRecord.startedAt
    ) private var activeTrees: [TreeRecord]
    /// 완성한 트리 기록을 관찰해 표시 번호를 갱신한다.
    @Query(filter: #Predicate<TreeRecord> { $0.completedAt != nil })
    private var completedTrees: [TreeRecord]

    /// 오늘의 출제 버튼에서 출제 탭으로 이동하는 동작.
    let onSelectQuestions: () -> Void

    /// 저장된 트리 기록을 읽어 화면을 구성하며 트리가 없으면 0칸으로 표시한다.
    var body: some View {
        let filledCount = TreeSlots.clampedCount(activeTrees.first?.decorationCount ?? 0)
        // FIXME: [가정] 시안의 N번째 트리 번호를 완성한 트리 수 + 1로 계산. 팀 확인 필요
        let treeNumber = completedTrees.count + 1

        let stats = UnsolvedQuestionStats.calculate(questions: questions, history: history)

        ViewThatFits(in: .vertical) {
            content(filledCount: filledCount, treeNumber: treeNumber, stats: stats)
            ScrollView {
                content(filledCount: filledCount, treeNumber: treeNumber, stats: stats, scrollable: true)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.roomBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { sessionID in
            // FIXME: [B 교체] 실제 퀴즈 화면 연결 시 같은 세션을 전달한다.
            if let session = history.first(where: { $0.id == sessionID }) {
                QuizEntryPlaceholderView(session: session)
            } else {
                ContentUnavailableView(
                    "세션을 찾을 수 없어요", systemImage: "exclamationmark.triangle"
                )
                .navigationTitle("세션 정보")
                .toolbar(.visible, for: .navigationBar)
            }
        }
    }

    private func content(
        filledCount: Int, treeNumber: Int, stats: UnsolvedQuestionStats, scrollable: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header(treeNumber: treeNumber)

            if scrollable {
                TaskTreePanel(filledCount: filledCount)
                    .aspectRatio(TreeSlots.aspectRatio, contentMode: .fit)
            } else {
                TaskTreePanel(filledCount: filledCount)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(-1)
            }

            remainingMessage(filledCount: filledCount)
                .font(.subheadline)
                .foregroundStyle(Color.roomSecondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(TaskHomeCopy.remainingText(filledCount: filledCount))

            if let session = services.sessions.resumableSession() {
                TaskResumeCard(session: session)
            } else {
                selectQuestionsButton
            }

            UnsolvedQuestionTiles(stats: stats)
        }
    }

    private func header(treeNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("산타의 작업실")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.roomPrimaryText)
                .accessibilityAddTraits(.isHeader)
            Text("크리스마스 · \(treeNumber)번째 트리")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.roomSecondaryText)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var selectQuestionsButton: some View {
        Button(action: onSelectQuestions) {
            Text("오늘의 출제")
                .font(.body.weight(.heavy))
                .frame(maxWidth: .infinity)
                .padding(14)
                .foregroundStyle(Color.roomOnAccentText)
                .background(Color.roomAccent, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityHint("출제 탭으로 이동합니다")
    }

    private func remainingMessage(filledCount: Int) -> Text {
        guard filledCount > 0 else {
            return Text(TaskHomeCopy.remainingText(filledCount: filledCount))
        }
        return Text("트리를 완성하려면 장식 ")
            + Text("\(TreeSlots.count - filledCount)개")
                .bold()
                .foregroundColor(.roomAccent)
            + Text("가 남았어요")
    }
}

#if DEBUG
@ViewBuilder
private func taskHomePreview(
    filledCount: Int, empty: Bool = false, resume: Bool = false
) -> some View {
    let questions = empty ? [] : Difficulty.allCases.flatMap { difficulty in
        QuizCategory.allCases.flatMap { category in
            TaskSelectPreviewData.questions(category: category, difficulty: difficulty, count: 1)
        }
    }
    let history = questions.filter { $0.difficulty == .easy || $0.category == .aiUsage }.map { question in
        TaskSelectPreviewData.session(
            questions: [question], category: question.category, difficulty: question.difficulty,
            answered: 1, status: .completed
        )
    }
    let resumable = resume ? [TaskSelectPreviewData.session(
        questions: TaskSelectPreviewData.questions(category: .swiftSyntax, difficulty: .normal, count: 10),
        category: .swiftSyntax, difficulty: .normal, answered: 6
    )] : []

    if let preview = try? TaskSelectPreviewData.environment(
        questions: questions, sessions: history + resumable,
        trees: [TreeRecord(decorationCount: filledCount)]
    ) {
        TaskHomeNavigationView(onSelectQuestions: {})
            .modelContainer(preview.container)
            .environment(\.services, preview.services)
    } else {
        ContentUnavailableView(
            "미리보기 데이터를 준비하지 못했어요", systemImage: "exclamationmark.triangle"
        )
    }
}

#Preview("작업실 · 빈 트리") {
    taskHomePreview(filledCount: 0)
}

#Preview("작업실 · 장식 6개") {
    taskHomePreview(filledCount: 6)
}

#Preview("작업실 · 완성") {
    taskHomePreview(filledCount: TreeSlots.count)
}

#Preview("작업실 · 다크") {
    taskHomePreview(filledCount: 6)
        .preferredColorScheme(.dark)
}

#Preview("작업실 · 큰 글자") {
    taskHomePreview(filledCount: 6)
        .dynamicTypeSize(.accessibility3)
}

#Preview("작업실 · 문제 없음") {
    taskHomePreview(filledCount: 0, empty: true)
}

#Preview("작업실 · 이어서 풀기") {
    TabView {
        taskHomePreview(filledCount: 6, resume: true)
            .tabItem { Label("작업실", systemImage: "gift") }
    }
}

#Preview("작업실 · 이어서 풀기 다크") {
    taskHomePreview(filledCount: 6, resume: true)
        .preferredColorScheme(.dark)
}

#Preview("작업실 · 이어서 풀기 큰 글자") {
    taskHomePreview(filledCount: 6, resume: true)
        .dynamicTypeSize(.accessibility3)
}
#endif
