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
            category: category, filter: filter, questions: [],
            selector: DecorationCountPreviewSelector(count: availableCount)
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

/// 진입 가능 경계 상황을 표시하기 위한 프리뷰 전용 구현.
// FIXME: [mock 교체] 실제 QuestionSelecting 통합 후 고정 후보 수 프리뷰를 실제 조건 데이터로 교체
private struct DecorationCountPreviewSelector: QuestionSelecting {
    let count: Int

    func select(
        category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, count: Int,
        questions: [Question], history: [QuizSession]
    ) -> [Question] {
        []
    }

    func availableCount(
        category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, questions: [Question]
    ) -> Int {
        count
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
