import SwiftData
import SwiftUI

/// 현재 트리와 남은 장식을 보여 주는 작업실 화면.
struct TaskHomeView: View {
    @Environment(\.services) private var services
    @Query private var questions: [Question]
    @Query private var history: [QuizSession]

    /// 서비스에서 현재 진행도와 완성한 트리 수를 읽어 화면을 구성한다.
    var body: some View {
        let filledCount = TreeSlots.clampedCount(services.trees.currentTree().decorationCount)
        // FIXME: [가정] 시안의 N번째 트리 번호를 완성한 트리 수 + 1로 계산. 팀 확인 필요
        let treeNumber = services.trees.completedTrees().count + 1

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
    }

    private func content(
        filledCount: Int, treeNumber: Int, stats: UnsolvedQuestionStats, scrollable: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("산타의 작업실")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.roomText)
                    .accessibilityAddTraits(.isHeader)
                Text("크리스마스 · \(treeNumber)번째 트리")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.roomSubText)
            }
            .fixedSize(horizontal: false, vertical: true)

            if scrollable {
                TaskTreePanel(filledCount: filledCount)
                    .aspectRatio(TreeSlots.designSize.width / TreeSlots.designSize.height, contentMode: .fit)
            } else {
                TaskTreePanel(filledCount: filledCount)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(-1)
            }

            remainingMessage(filledCount: filledCount)
                .font(.subheadline)
                .foregroundStyle(Color.roomSubText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(TaskHomeCopy.remainingText(filledCount: filledCount))

            UnsolvedQuestionTiles(stats: stats)
        }
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

private func taskHomePreview(filledCount: Int, empty: Bool = false) -> some View {
    let source = AppServices.preview
    let trees = MockTreeManager()
    trees.currentTree().decorationCount = filledCount
    let services = AppServices(
        settings: source.settings,
        selector: source.selector,
        sessions: source.sessions,
        trees: trees,
        feedback: source.feedback,
        media: source.media,
        traceScenes: source.traceScenes
    )
    let container = Result {
        let container = try ModelContainerFactory.make(inMemory: true)
        if empty == false {
            for difficulty in Difficulty.allCases {
                for category in QuizCategory.allCases {
                    let question = Question(
                        text: "미리보기 문제", choices: ["하나", "둘", "셋", "넷"],
                        correctIndex: 0, explanation: "미리보기 해설",
                        category: category, difficulty: difficulty
                    )
                    container.mainContext.insert(question)
                    if difficulty == .easy || category == .aiUsage {
                        let session = QuizSession(
                            category: category, difficulty: difficulty,
                            questionSnapshots: [QuestionSnapshot(question)],
                            passThresholdPercent: 80
                        )
                        session.answers = [
                            SessionAnswer(questionID: question.id, selectedIndex: 0, isCorrect: true)
                        ]
                        session.currentIndex = session.answers.count
                        session.status = .completed
                        container.mainContext.insert(session)
                    }
                }
            }
            try container.mainContext.save()
        }
        return container
    }
    return Group {
        switch container {
        case .success(let container):
            TaskHomeView()
                .modelContainer(container)
                .environment(\.services, services)
        case .failure:
            ContentUnavailableView(
                "미리보기 데이터를 준비하지 못했어요",
                systemImage: "exclamationmark.triangle"
            )
        }
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
