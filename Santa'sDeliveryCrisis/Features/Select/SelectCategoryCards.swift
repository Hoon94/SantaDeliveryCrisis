import SwiftUI
import UIKit

/// 마지막 선택을 유지하며 여러 카테고리를 고르는 카드 영역.
struct SelectCategoryCards: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 팝업에서 편집 중인 필터. 카테고리 변경 규칙은 SelectFilter에 맡긴다.
    @Binding var filter: SelectFilter

    /// 외부 추천 결과. 선택 여부와 관계없이 해당 카드에만 추천을 표시한다.
    var recommendedCategory: QuizCategory? = nil

    /// 일반 글자에서는 두 열, 접근성 글자에서는 한 열로 카드를 배치한다.
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("카테고리 (여러 개 선택 가능)")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.nightSubText)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 7),
                    count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
                ),
                spacing: 8
            ) {
                ForEach(QuizCategory.allCases, id: \.self) { category in
                    categoryCard(category)
                }
            }
        }
    }

    private func categoryCard(_ category: QuizCategory) -> some View {
        let isSelected = filter.categories.contains(category)
        let isLastSelection = isSelected && filter.categories.count == 1
        let isRecommended = recommendedCategory == category
        return Button {
            filter.toggleCategory(category)
            if isLastSelection {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "마지막 하나는 해제할 수 없어요"
                )
            }
        } label: {
            HStack(spacing: 4) {
                Text(emoji(category))
                    .font(.body)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.categoryName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.nightText)
                    if isRecommended {
                        Text("추천")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.nightOnAccent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 1)
                            .background(Color.nightAccent, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isSelected ? category.themeColor : .nightLine)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.nightSoft)
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(category.themeColor.opacity(0.16))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? category.themeColor : .nightLine, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecommended ? "\(category.categoryName), 추천" : category.categoryName)
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isLastSelection ? "마지막 하나는 해제할 수 없어요" : "선택을 변경합니다")
    }

    private func emoji(_ category: QuizCategory) -> String {
        switch category {
        case .aiUsage: "🤖"
        case .swiftSyntax: "🐦"
        case .hig: "🎨"
        case .swiftUIPractice: "🧩"
        }
    }
}

private struct SelectCategoryCardsPreview: View {
    @State private var filter: SelectFilter

    init(categories: Set<QuizCategory>) {
        _filter = State(initialValue: SelectFilter(categories: categories))
    }

    var body: some View {
        ScrollView {
            SelectCategoryCards(filter: $filter)
                .padding(16)
        }
        .background(Color.nightCard)
    }
}

#Preview("카테고리 · 전체 선택") {
    SelectCategoryCardsPreview(categories: Set(QuizCategory.allCases))
}

#Preview("카테고리 · 하나 선택") {
    SelectCategoryCardsPreview(categories: [.swiftSyntax])
}

#Preview("카테고리 · 큰 글자") {
    SelectCategoryCardsPreview(categories: [.swiftSyntax])
        .dynamicTypeSize(.accessibility5)
}

#Preview("카테고리 · 다크") {
    SelectCategoryCardsPreview(categories: Set(QuizCategory.allCases))
        .preferredColorScheme(.dark)
}
