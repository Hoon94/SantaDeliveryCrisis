import SwiftData
import SwiftUI

/// 현재 트리와 남은 장식을 보여 주는 작업실 화면.
struct TaskHomeView: View {
    @Environment(\.services) private var services
    @State private var activeQuizSession: QuizSession?

    /// 기본 출제 설정을 열도록 상위 탭 화면에 요청한다.
    let onSelectQuestions: () -> Void

    /// 아직 트리에 도착하지 않은 장식은 날아와 닿을 때까지 숨긴다.
    @Environment(\.rewardFlight) private var rewardFlight
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
    /// 가로가 넓은 환경(iPad)에서 트리 패널이 커지는 폭의 상한.
    private static let regularPanelMaxWidth: CGFloat = 640

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// 저장된 트리 기록을 읽어 화면을 구성하며 트리가 없으면 0칸으로 표시한다.
    var body: some View {
        let completing = rewardFlight.pendingCompletion ?? rewardFlight.completion
        let savedCount = completing?.treeDecorationCount ?? TreeSlots.clampedCount(activeTrees.first?.decorationCount ?? 0)
        let filledCount = max(savedCount - rewardFlight.pendingCount, 0)
        let ornamentTasks = completing.map { summary in
            (summary.treeRewardStages.filter { $0 != summary.stage } + [summary.stage]).map(\.task)
        } ?? earnedTasks(in: activeTrees.first)
        // 완성 연출 중에는 방금 완성한 트리 번호를 유지한다.
        let treeNumber = completedTrees.count + (completing?.result.treeCompleted == true ? 0 : 1)

        let stats = UnsolvedQuestionStats.calculate(questions: questions, history: history)

        ViewThatFits(in: .vertical) {
            content(filledCount: filledCount, ornamentTasks: ornamentTasks, treeNumber: treeNumber, stats: stats)
            ScrollView {
                content(
                    filledCount: filledCount, ornamentTasks: ornamentTasks,
                    treeNumber: treeNumber, stats: stats, scrollable: true
                )
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.roomBackground)
        .navigationTitle("산타의 작업실")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ScreenTitleToolbar(title: "산타의 작업실", color: .roomPrimaryText)
        }
        .fullScreenCover(item: $activeQuizSession) { session in
            QuizEntryPresentation(session: session)
                .presentationBackground(.clear)
        }
    }

    private func content(
        filledCount: Int, ornamentTasks: [WorkshopTask], treeNumber: Int,
        stats: UnsolvedQuestionStats, scrollable: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("크리스마스 · \(treeNumber)번째 트리")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.roomSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if scrollable {
                TaskTreePanel(filledCount: filledCount, ornamentTasks: ornamentTasks)
                    .aspectRatio(TreeSlots.aspectRatio, contentMode: .fit)
                    .frame(maxWidth: horizontalSizeClass == .regular ? Self.regularPanelMaxWidth : .infinity)
                    .frame(maxWidth: .infinity)
            } else if horizontalSizeClass == .regular {
                // iPad: 패널을 남는 공간에 맞춰 비율을 유지한 채 줄이고 가운데에 둔다(잘림 방지).
                TaskTreePanel(filledCount: filledCount, ornamentTasks: ornamentTasks)
                    .aspectRatio(TreeSlots.aspectRatio, contentMode: .fit)
                    .frame(maxWidth: Self.regularPanelMaxWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(-1)
            } else {
                TaskTreePanel(filledCount: filledCount, ornamentTasks: ornamentTasks)
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

            learningAction

            UnsolvedQuestionTiles(stats: stats)
        }
    }

    /// 현재 트리에 새 보상을 지급한 세션의 작업을 획득 시각순으로 읽는다.
    /// 재풀이와 이전 트리를 완성한 세션은 제외하며 보상을 다시 계산하거나 저장하지 않는다.
    private func earnedTasks(in tree: TreeRecord?) -> [WorkshopTask] {
        guard let tree else { return [] }
        if TreeCompletionConfiguration.startBeforeFinalStage {
            return QuizStage.all.filter { $0.isEarned(in: tree.rewardMask) }.map(\.task)
        }
        return history.filter { session in
            guard session.status == .completed, session.rewardOutcome == .earned,
                  !session.treeCompleted, let finishedAt = session.finishedAt else { return false }
            return finishedAt >= tree.startedAt
        }
        .sorted {
            if $0.finishedAt == $1.finishedAt { return $0.startedAt < $1.startedAt }
            return ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)
        }
        .prefix(tree.decorationCount)
        .map(\.task)
    }

    /// 진행 중 세션이 있으면 복원하고, 없으면 출제 탭으로 이동하는 하나의 진입 버튼.
    private var learningAction: some View {
        let session = services.sessions.resumableSession()
        return Button {
            if let session {
                activeQuizSession = session
            } else {
                onSelectQuestions()
            }
        } label: {
            VStack(spacing: 4) {
                Text(session == nil ? "퀴즈 시작하기" : "이어서 풀기")
                    .font(.body.weight(.heavy))
                if let session {
                    Text("\(QuizStage(task: session.task, difficulty: session.difficulty).title) · \(session.difficulty.displayName) · \(session.answers.count) / \(session.questionSnapshots.count) 문제")
                        .font(.caption)
                        .opacity(0.85)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(14)
            .foregroundStyle(Color.roomOnAccentText)
            .background(Color.roomAccent, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityHint(session == nil ? "출제 탭에서 기본 출제 설정을 엽니다" : "저장된 퀴즈를 이어서 풉니다")
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
    filledCount: Int, empty: Bool = false, resumeAnsweredCount: Int? = nil
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
    let resumableQuestions = resumeAnsweredCount == nil ? [] : TaskSelectPreviewData.questions(
        category: .swiftSyntax, difficulty: .normal, count: 5
    )
    let resumable = resumeAnsweredCount.map { answered in
        TaskSelectPreviewData.session(
            questions: resumableQuestions, category: .swiftSyntax, difficulty: .normal, answered: answered
        )
    }
    if let preview = try? TaskSelectPreviewData.environment(
        questions: questions + resumableQuestions, sessions: history + [resumable].compactMap { $0 },
        trees: [TreeRecord(decorationCount: filledCount)]
    ) {
        NavigationStack { TaskHomeView(onSelectQuestions: {}) }
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
    taskHomePreview(filledCount: 6, resumeAnsweredCount: 2)
}

#Preview("작업실 · 이어서 풀기 · 큰 글자") {
    taskHomePreview(filledCount: 6, resumeAnsweredCount: 2)
        .dynamicTypeSize(.accessibility3)
}

#Preview("작업실 · 모든 답 저장 후 결과 복원") {
    taskHomePreview(filledCount: 6, resumeAnsweredCount: 5)
}

#endif
