import SwiftUI

/// 켜짐 상태와 퀴즈 진입 허용 여부를 함께 적용하는 장식 버튼.
struct SelectableDecoration: View {
    /// 선택한 카테고리 전체의 후보 수에서 계산한 활성 상태.
    let availability: DecorationAvailability

    /// 현재 트리의 획득 칸. 시작 가능 여부와 별도로 표시한다.
    var rewardMask: Int = 0

    /// 활성 장식을 눌렀을 때만 호출하는 세션 진입 동작.
    let onSelect: () -> Void

    /// 비활성 장식은 흐리게 표시하고 탭과 접근성 실행을 차단한다.
    var body: some View {
        VStack(spacing: 12) {
            Button {
                guard availability.isEnabled else { return }
                onSelect()
            } label: {
                DecorationView(task: availability.task, isLit: availability.isEnabled)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(availability.isEnabled == false)
            .accessibilityLabel("\(availability.task.displayName), \(availability.isEnabled ? "켜짐" : "꺼짐")")

        }
    }

}

#if DEBUG
private struct SelectableDecorationPreview: View {
    let availableCount: Int
    let requestedCount: Int
    @State private var didSelect = false

    var body: some View {
        let category = QuizCategory.swiftSyntax
        let filter = SelectFilter(categories: [category], count: requestedCount)
        let availability = DecorationAvailability.calculate(
            filter: filter,
            questions: TaskSelectPreviewData.questions(category: category, difficulty: .normal, count: availableCount),
            selector: QuestionSelector()
        )[0]
        VStack(spacing: 12) {
            SelectableDecoration(availability: availability) {
                didSelect = true
            }
            if didSelect {
                Text("퀴즈 진입을 선택했어요")
                    .font(.caption)
                    .foregroundStyle(Color.nightPrimaryText)
            }
        }
        .padding(30)
        .background(Color.nightBackgroundTop)
    }
}

private struct DecorationAvailabilityPreview: View {
    let filter: SelectFilter

    var body: some View {
        let normalCounts = [5, 3, 0, 7]
        let questions = zip(QuizCategory.allCases, normalCounts).flatMap { category, count in
            TaskSelectPreviewData.questions(category: category, difficulty: .normal, count: count)
                + TaskSelectPreviewData.questions(category: category, difficulty: .easy, count: 5)
        }
        let results = DecorationAvailability.calculate(
            filter: filter, questions: questions, selector: QuestionSelector()
        )
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                ForEach(results, id: \.task) { result in
                    SelectableDecoration(availability: result, onSelect: {})
                }
            }
            .padding(30)
        }
        .scrollClipDisabled()
        .background(Color.nightBackgroundTop)
    }
}

#Preview("장식 진입 · 3개 중 5개 요청 · 꺼짐") {
    SelectableDecorationPreview(availableCount: 3, requestedCount: 5)
}

#Preview("장식 진입 · 0개 · 꺼짐") {
    SelectableDecorationPreview(availableCount: 0, requestedCount: 5)
}

#Preview("장식 진입 · 요청 수와 같음 · 켜짐") {
    SelectableDecorationPreview(availableCount: 5, requestedCount: 5)
}

#Preview("장식 진입 · 요청 수보다 많음 · 켜짐") {
    SelectableDecorationPreview(availableCount: 10, requestedCount: 5)
}

#Preview("장식 진입 · 큰 글자") {
    SelectableDecorationPreview(availableCount: 3, requestedCount: 5)
        .dynamicTypeSize(.accessibility5)
}

#Preview("네 장식 · 보통 후보 5·3·0·7개") {
    DecorationAvailabilityPreview(filter: SelectFilter())
}

#Preview("네 장식 · 두 카테고리 후보 합산") {
    DecorationAvailabilityPreview(filter: SelectFilter(categories: [.aiUsage, .swiftSyntax]))
}

#Preview("네 장식 · 쉬움 모두 켜짐") {
    DecorationAvailabilityPreview(filter: SelectFilter(difficulty: .easy))
}

#Preview("네 장식 · 10문제 요청 모두 꺼짐") {
    DecorationAvailabilityPreview(filter: SelectFilter(count: 10))
}
#endif
