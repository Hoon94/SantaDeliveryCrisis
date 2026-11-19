import SwiftUI

/// 해설, 힌트, 학습 자료(제목과 주소), 태그를 입력하는 화면. 문제 편집 화면(S11)에서 들어온다.
/// 입력값은 편집 화면과 같은 `QuestionDraft`를 공유한다.
struct QuestionExtrasEditView: View {
    @Binding var draft: QuestionDraft

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                section("해설 (필수)") {
                    TextField("정답이 왜 맞는지 적어 주세요", text: $draft.explanation, axis: .vertical)
                        .lineLimit(3...10)
                }
                if QuestionDraft.trimmed(draft.explanation).isEmpty {
                    Text("해설을 입력해 주세요")
                        .font(.caption.bold())
                        .foregroundStyle(Color.roomNegative)
                        .padding(.top, -6)
                }
                section("힌트") {
                    TextField("풀이에 도움이 되는 힌트", text: $draft.hint, axis: .vertical)
                        .lineLimit(1...4)
                }
                section("학습 자료 제목") {
                    TextField("예: Swift 공식 문서", text: $draft.resourceTitle)
                }
                section("학습 자료 주소") {
                    TextField("https://", text: $draft.resourceURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                if !draft.isResourceURLValid {
                    Text("http 또는 https로 시작하는 주소를 입력해 주세요")
                        .font(.caption.bold())
                        .foregroundStyle(Color.roomNegative)
                        .padding(.top, -6)
                }
                section("태그") {
                    TextField("쉼표로 구분해 입력해요", text: $draft.tagsText, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .foregroundStyle(Color.roomPrimaryText)
        .background(Color.roomBackground)
        .navigationTitle("추가 정보")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Color.roomBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        let hasError = (title == "학습 자료 주소" && !draft.isResourceURLValid)
            || (title == "해설 (필수)" && QuestionDraft.trimmed(draft.explanation).isEmpty)
        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)
            content()
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roomCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hasError ? Color.roomNegative : Color.roomBorder, lineWidth: hasError ? 1.5 : 1)
        )
    }
}

#Preview {
    @Previewable @State var draft = QuestionDraft()
    return NavigationStack { QuestionExtrasEditView(draft: $draft) }
}
