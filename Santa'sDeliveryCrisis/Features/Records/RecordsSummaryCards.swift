import SwiftUI

/// 요약 카드 3개: 시도, 평균 점수, 완성 트리. 카드를 눌러도 동작은 없다.
struct RecordsSummaryCards: View {
    /// 끝낸 세션 수
    let attemptCount: Int
    /// 세션 정답률의 평균. 없으면 nil
    let averageScore: Int?
    /// 지금까지 완성한 트리 수
    let completedTreeCount: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        layout {
            card(title: "시도", value: "\(attemptCount)회")
            card(title: "평균 점수", value: averageScore.map { "\($0)점" } ?? "-")
            card(title: "완성 트리", value: "\(completedTreeCount)그루")
        }
    }

    private func card(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.roomSub)
            Text(value)
                .font(.title3.bold())
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .roomCard(padding: EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

#Preview {
    RecordsSummaryCards(attemptCount: 12, averageScore: 76, completedTreeCount: 2)
        .padding()
        .background(Color.roomBackground)
}
