import SwiftUI

/// 실제 장식 선택 화면을 연결하기 전까지 적용 조건과 다시 열기 칩을 표시한다.
struct SelectDecorationPlaceholder: View {
    /// 팝업에서 마지막으로 적용한 설정.
    let filter: SelectFilter

    /// 마지막 적용값으로 설정 팝업을 다시 여는 동작.
    let onEdit: () -> Void

    /// 적용 조건을 표시하는 칩과 후속 구현을 위한 자리표시 영역.
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("출제")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.nightText)
                .accessibilityAddTraits(.isHeader)

            Button(action: onEdit) {
                Label(
                    "\(filter.difficulty.displayName) · 카테고리 \(filter.categories.count)개 · \(filter.count)문제",
                    systemImage: "gearshape"
                )
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.nightText)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(Color.nightCard, in: Capsule())
                .overlay { Capsule().strokeBorder(Color.nightLine, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("출제 설정, \(filter.difficulty.displayName), 카테고리 \(filter.categories.count)개, \(filter.count)문제")
            .accessibilityHint("출제 설정 팝업을 다시 엽니다")

            Spacer(minLength: 0)
            Text("출제 조건이 적용됐어요")
                .font(.headline)
                .foregroundStyle(Color.nightText)
                .frame(maxWidth: .infinity)
            Text("장식 선택 화면을 준비하고 있어요")
                .font(.subheadline)
                .foregroundStyle(Color.nightSubText)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
        }
    }
}

#Preview("적용 조건 · 기본값") {
    SelectDecorationPlaceholder(filter: SelectFilter(), onEdit: {})
        .padding(14)
        .background(Color.nightBackgroundTop)
}

#Preview("적용 조건 · 큰 글자") {
    ScrollView {
        SelectDecorationPlaceholder(
            filter: SelectFilter(difficulty: .hard, categories: [.aiUsage, .hig], count: 15),
            onEdit: {}
        )
        .padding(14)
    }
    .background(Color.nightBackgroundTop)
    .dynamicTypeSize(.accessibility5)
}
