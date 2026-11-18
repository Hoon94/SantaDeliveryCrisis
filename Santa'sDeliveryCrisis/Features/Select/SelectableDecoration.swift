import SwiftUI

/// 켜짐 상태와 퀴즈 진입 허용 여부를 함께 적용하는 장식 버튼.
struct SelectableDecoration: View {
    /// 후보 수와 필터에서 계산한 활성 상태 및 부족 안내.
    let availability: DecorationAvailability

    /// 활성 장식을 눌렀을 때만 호출하는 세션 진입 동작.
    let onSelect: () -> Void

    /// 비활성 장식은 흐리게 표시하고 탭과 접근성 실행을 차단한다.
    var body: some View {
        VStack(spacing: 12) {
            Button {
                guard availability.isEnabled else { return }
                onSelect()
            } label: {
                DecorationView(category: availability.category, isLit: availability.isEnabled)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(availability.isEnabled == false)
            .accessibilityLabel("\(availability.category.taskName), \(availability.isEnabled ? "켜짐" : "꺼짐")")

            if let count = availability.shortageCount {
                Text("\(count)문제만 있어요")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.nightText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("\(availability.category.taskName), \(count)문제만 있어요")
            }
        }
    }
}

private struct SelectableDecorationPreview: View {
    let availableCount: Int
    let requestedCount: Int
    var isSelected = true
    @State private var didSelect = false

    var body: some View {
        let category = QuizCategory.swiftSyntax
        let filter = SelectFilter(
            categories: isSelected ? [.swiftSyntax] : [.hig], count: requestedCount
        )
        let availability = DecorationAvailability.calculate(
            category: category, filter: filter,
            questions: previewQuestions(category: category, difficulty: .normal, count: availableCount),
            selector: PreviewQuestionSelector()
        )
        VStack(spacing: 12) {
            SelectableDecoration(availability: availability) {
                didSelect = true
            }
            if didSelect {
                Text("퀴즈 진입을 선택했어요")
                    .font(.caption)
                    .foregroundStyle(Color.nightText)
            }
        }
        .padding(30)
        .background(Color.nightBackgroundTop)
    }
}

private func previewQuestions(
    category: QuizCategory, difficulty: Difficulty, count: Int
) -> [Question] {
    (0..<max(0, count)).map { index in
        Question(
            text: "장식 미리보기 문제 \(index + 1)", choices: ["하나", "둘", "셋", "넷"],
            correctIndex: 0, explanation: "미리보기 해설",
            category: category, difficulty: difficulty
        )
    }
}

private struct DecorationAvailabilityPreview: View {
    let filter: SelectFilter

    var body: some View {
        let normalCounts = [5, 3, 0, 7]
        let questions = zip(QuizCategory.allCases, normalCounts).flatMap { category, count in
            previewQuestions(category: category, difficulty: .normal, count: count)
                + previewQuestions(category: category, difficulty: .easy, count: 5)
        }
        let results = DecorationAvailability.calculate(
            filter: filter, questions: questions, selector: PreviewQuestionSelector()
        )
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                ForEach(results, id: \.category) { result in
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

#Preview("장식 진입 · 선택 안 함 · 꺼짐") {
    SelectableDecorationPreview(availableCount: 10, requestedCount: 5, isSelected: false)
}

#Preview("장식 진입 · 큰 글자") {
    SelectableDecorationPreview(availableCount: 3, requestedCount: 5)
        .dynamicTypeSize(.accessibility5)
}

#Preview("네 장식 · 보통 후보 5·3·0·7개") {
    DecorationAvailabilityPreview(filter: SelectFilter())
}

#Preview("네 장식 · 두 카테고리 선택") {
    DecorationAvailabilityPreview(filter: SelectFilter(categories: [.aiUsage, .swiftSyntax]))
}

#Preview("네 장식 · 쉬움 모두 켜짐") {
    DecorationAvailabilityPreview(filter: SelectFilter(difficulty: .easy))
}

#Preview("네 장식 · 10문제 요청 모두 꺼짐") {
    DecorationAvailabilityPreview(filter: SelectFilter(count: 10))
}
