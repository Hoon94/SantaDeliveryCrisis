import SwiftUI

/// 문제 제목과 태그를 함께 검색하는 입력 칸.
struct ManageSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.roomSecondaryText)
                .accessibilityHidden(true)
            TextField("문제 또는 태그 검색", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.roomSecondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.roomCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.roomBorder, lineWidth: 1))
    }
}

/// 카테고리(문제 유형)와 난이도로 거르는 칩 두 줄. 칩에는 "HIG"처럼 카테고리 이름을 쓴다. 각 줄에서 하나만 고르고 "전체"는 조건 없음이다.
struct ManageFilterBar: View {
    @Binding var category: QuizCategory?
    @Binding var difficulty: Difficulty?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            chipRow {
                RoomChip(title: "전체", style: category == nil ? .selected : .normal) { category = nil }
                ForEach(QuizCategory.allCases, id: \.self) { item in
                    RoomChip(title: item.categoryName, style: category == item ? .selected : .normal) {
                        category = item
                    }
                }
            }
            .accessibilityLabel("카테고리 필터")
            chipRow {
                RoomChip(title: "전체", style: difficulty == nil ? .selected : .normal) { difficulty = nil }
                ForEach(Difficulty.allCases, id: \.self) { item in
                    RoomChip(title: item.displayName, style: difficulty == item ? .selected : .normal) {
                        difficulty = item
                    }
                }
            }
            .accessibilityLabel("난이도 필터")
        }
    }

    private func chipRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) { content() }
        }
    }
}

#Preview {
    @Previewable @State var category: QuizCategory?
    @Previewable @State var difficulty: Difficulty?
    @Previewable @State var text = ""
    return VStack {
        ManageSearchField(text: $text)
        ManageFilterBar(category: $category, difficulty: $difficulty)
    }
    .padding()
    .background(Color.roomBackground)
}
