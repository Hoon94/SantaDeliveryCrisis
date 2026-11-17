import SwiftUI

/// 현재 트리와 남은 장식을 보여 주는 작업실 화면.
struct TaskHomeView: View {
    @Environment(\.services) private var services

    /// 서비스에서 현재 진행도와 완성한 트리 수를 읽어 화면을 구성한다.
    var body: some View {
        let filledCount = TreeSlots.clampedCount(services.trees.currentTree().decorationCount)
        // FIXME: [가정] 시안의 N번째 트리 번호를 완성한 트리 수 + 1로 계산. 팀 확인 필요
        let treeNumber = services.trees.completedTrees().count + 1

        ViewThatFits(in: .vertical) {
            content(filledCount: filledCount, treeNumber: treeNumber)
            ScrollView {
                content(filledCount: filledCount, treeNumber: treeNumber)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.roomBackground)
    }

    private func content(filledCount: Int, treeNumber: Int) -> some View {
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

            TaskTreePanel(filledCount: filledCount)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(-1)

            remainingMessage(filledCount: filledCount)
                .font(.subheadline)
                .foregroundStyle(Color.roomSubText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(TaskHomeCopy.remainingText(filledCount: filledCount))
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

private func taskHomePreview(filledCount: Int) -> some View {
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
    return TaskHomeView().environment(\.services, services)
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
