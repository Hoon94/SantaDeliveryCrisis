import SwiftUI

/// 해설을 입력하는 화면. 문제 편집 화면(S11)에서 "해설" 줄을 누르면 열린다.
/// 해설은 필수라서 비어 있으면 저장할 수 없다. 입력값은 편집 화면과 같은 `QuestionDraft`를 공유한다.
struct QuestionExplanationEditView: View {
    @Binding var draft: QuestionDraft

    private var isEmpty: Bool { QuestionDraft.trimmed(draft.explanation).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("해설 (필수)")
                        .font(.caption)
                        .foregroundStyle(Color.roomSecondaryText)
                    TextField("정답이 왜 맞는지 적어 주세요", text: $draft.explanation, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(5...20)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.roomCardBackground, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isEmpty ? Color.roomNegative : Color.roomBorder, lineWidth: isEmpty ? 1.5 : 1)
                )
                if isEmpty {
                    Text("해설을 입력해 주세요")
                        .font(.caption.bold())
                        .foregroundStyle(Color.roomNegative)
                        .padding(.top, -6)
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .foregroundStyle(Color.roomPrimaryText)
        .background(Color.roomBackground)
        .navigationTitle("해설")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Color.roomBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    @Previewable @State var draft = QuestionDraft()
    return NavigationStack { QuestionExplanationEditView(draft: $draft) }
}
