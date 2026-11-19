import SwiftData
import SwiftUI

/// 문제 편집 화면(S11). 일반 문제를 새로 만들거나 고친다.
/// 보기는 항상 4개이고 정답은 1개다. 변경이 있는 채로 [취소]를 누르면 버릴지 확인한다(S11-A1).
struct QuestionEditView: View {
    /// 고칠 문제. nil이면 새 문제를 만든다.
    private let question: Question?
    private let original: QuestionDraft

    @State private var draft: QuestionDraft
    /// 입력을 시작한 뒤에만 오류 문구를 보여 준다.
    @State private var hasInteracted = false
    @State private var isDiscardAlertPresented = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.services) private var services
    /// 같은 문제가 이미 있는지 비교하려고 모든 문제를 읽는다.
    @Query private var questions: [Question]

    /// - Parameter question: 고칠 문제. nil이면 새 문제를 만든다.
    init(question: Question?) {
        self.question = question
        // `map(QuestionDraft.init)`처럼 초기화 함수를 그대로 넘기지 않고 직접 호출한다.
        let initial: QuestionDraft
        if let question {
            initial = QuestionDraft(question)
        } else {
            initial = QuestionDraft()
        }
        self.original = initial
        _draft = State(initialValue: initial)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                textField
                if showsError(.textEmpty) { errorText("문제 내용은 비워 둘 수 없어요") }
                if isTextDuplicate { errorText("이미 생성된 문제가 있습니다") }
                QuestionMediaSection(draft: $draft)
                choicesCard
                if showsError(.choicesIncomplete) { errorText("보기 4개를 모두 입력해야 저장할 수 있어요") }
                if showsError(.duplicateChoices) { errorText("이미 작성된 항목이 있습니다") }
                pickerRow(title: "카테고리") {
                    Picker("카테고리", selection: $draft.category) {
                        ForEach(QuizCategory.allCases, id: \.self) { Text($0.categoryName).tag($0) }
                    }
                }
                pickerRow(title: "난이도") {
                    Picker("난이도", selection: $draft.difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }
                extrasLink
                if showsError(.explanationEmpty) { errorText("해설을 입력해 주세요") }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .foregroundStyle(Color.roomPrimaryText)
        .background(Color.roomBackground)
        .navigationTitle(question == nil ? "새 문제" : "문제 편집")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Color.roomBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("취소", action: cancel)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.roomAccent)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("저장", action: save)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.roomAccent)
                    .disabled(!canSave)
                    .accessibilityHint(canSave ? "" : "필수 항목을 모두 올바르게 입력해야 저장할 수 있어요")
            }
        }
        .onChange(of: draft) { _, _ in hasInteracted = true }
        .alert(discardAlertTitle, isPresented: $isDiscardAlertPresented) {
            Button("계속 작성", role: .cancel) {}
            Button("지우기", role: .destructive, action: discardAndClose)
        } message: {
            Text("저장하지 않은 내용은 사라져요.")
        }
        .alert("문제를 저장하지 못했어요", isPresented: isErrorPresented) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - 입력 영역

    private var textField: some View {
        let hasError = showsError(.textEmpty) || isTextDuplicate
        return VStack(alignment: .leading, spacing: 2) {
            Text("문제")
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)
            TextField("문제를 입력해 주세요", text: $draft.text, axis: .vertical)
                .lineLimit(1...6)
                .font(.subheadline.bold())
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

    private var choicesCard: some View {
        VStack(spacing: 0) {
            ForEach(0..<QuestionDraft.choiceCount, id: \.self) { index in
                if index > 0 { Divider().overlay(Color.roomBorder) }
                choiceRow(index)
            }
        }
        .roomCardBackground(padding: EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
    }

    private func choiceRow(_ index: Int) -> some View {
        let label = Self.choiceLabels[index]
        let isCorrect = draft.correctIndex == index
        let isDuplicate = hasInteracted && draft.duplicateChoiceIndices.contains(index)
        return HStack(alignment: .top, spacing: 10) {
            Button {
                draft.correctIndex = index
            } label: {
                Image(systemName: isCorrect ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCorrect ? Color.roomAccent : Color.roomSecondaryText)
                    .frame(minWidth: 32, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("보기 \(label)를 정답으로 선택")
            .accessibilityAddTraits(isCorrect ? .isSelected : [])
            Text("\(label).")
                .font(.subheadline)
                .foregroundStyle(isDuplicate ? Color.roomNegative : Color.roomSecondaryText)
                .padding(.top, 12)
            TextField("보기를 입력해 주세요", text: choiceBinding(index), axis: .vertical)
                .font(.subheadline)
                .lineLimit(1...4)
                .padding(.vertical, 12)
                .accessibilityLabel("보기 \(label)")
                .accessibilityValue(isDuplicate ? "이미 작성된 항목이 있습니다" : "")
        }
    }

    private func pickerRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
            Spacer()
            content()
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(Color.roomSecondaryText)
        }
        .font(.subheadline)
        .roomCardBackground(padding: EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 8))
    }

    private var extrasLink: some View {
        NavigationLink {
            QuestionExtrasEditView(draft: $draft)
        } label: {
            HStack {
                Text("해설 · 힌트 · 학습 자료 · 태그")
                    .font(.subheadline)
                Spacer()
                if showsError(.resourceURLInvalid) || showsError(.explanationEmpty) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.roomNegative)
                        .accessibilityLabel(extrasWarningLabel)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color.roomSecondaryText)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 36)
            .roomCardBackground(padding: EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
        }
        .buttonStyle(.plain)
    }

    /// 해설·힌트·학습 자료·태그 줄의 경고 아이콘을 VoiceOver가 읽을 말
    private var extrasWarningLabel: String {
        switch (showsError(.explanationEmpty), showsError(.resourceURLInvalid)) {
        case (true, true): "해설과 학습 자료 주소를 확인해 주세요"
        case (true, false): "해설을 입력해 주세요"
        default: "학습 자료 주소를 확인해 주세요"
        }
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.caption.bold())
            .foregroundStyle(Color.roomNegative)
            .padding(.top, -6)
    }

    // MARK: - 동작

    private static let choiceLabels = ["A", "B", "C", "D"]

    /// 취소할 때 뜨는 알림의 제목. 고치던 문제는 "수정한 내용", 새 문제는 "작성한 내용"이라고 부른다.
    private var discardAlertTitle: String {
        question == nil ? "작성한 내용을 지울까요?" : "수정한 내용을 지울까요?"
    }

    /// 같은 문제가 이미 있는지. 공백만 다른 문제도 같은 문제로 본다.
    /// 고치는 중인 문제는 비교에서 빼고, 문제 내용을 바꾸지 않았다면 따지지 않는다.
    private var isTextDuplicate: Bool {
        let key = QuestionDraft.normalizedKey(draft.text)
        guard !key.isEmpty else { return false }
        if question != nil, key == QuestionDraft.normalizedKey(original.text) { return false }
        return questions.contains { $0.id != question?.id && QuestionDraft.normalizedKey($0.text) == key }
    }

    /// 저장할 수 있는지. 입력값이 올바르고 같은 문제가 없어야 한다.
    private var canSave: Bool { draft.isValid && !isTextDuplicate }

    private func showsError(_ issue: QuestionDraft.Issue) -> Bool {
        hasInteracted && draft.issues.contains(issue)
    }

    private func choiceBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { draft.choices.indices.contains(index) ? draft.choices[index] : "" },
            set: { newValue in
                guard draft.choices.indices.contains(index) else { return }
                draft.choices[index] = newValue
            }
        )
    }

    private var editor: QuestionEditor {
        QuestionEditor(context: modelContext, media: services.media)
    }

    private func save() {
        guard canSave else { return }
        do {
            if let question {
                try editor.update(question, with: draft)
            } else {
                try editor.create(draft)
            }
            dismiss()
        } catch QuestionEditorError.seedQuestion {
            errorMessage = "기본 문제는 수정할 수 없어요."
        } catch QuestionEditorError.animationQuestion {
            errorMessage = "애니메이션 문제는 수정할 수 없어요."
        } catch QuestionEditorError.duplicateText {
            errorMessage = "이미 생성된 문제가 있습니다"
        } catch {
            errorMessage = "잠시 후 다시 시도해 주세요."
        }
    }

    private func cancel() {
        if draft == original {
            discardAndClose()
        } else {
            isDiscardAlertPresented = true
        }
    }

    /// 변경을 버리고 닫는다. 이번 편집에서 새로 복사한 이미지·영상 파일도 정리 대상이 된다.
    private func discardAndClose() {
        editor.discardUnsavedMedia()
        dismiss()
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }
}

#if DEBUG
#Preview("새 문제") {
    NavigationStack { QuestionEditView(question: nil) }
        .modelContainer(ManagePreviewData.container(withQuestions: false))
}

#Preview("문제 편집") {
    NavigationStack { QuestionEditView(question: ManagePreviewData.sampleUserQuestion()) }
        .modelContainer(ManagePreviewData.container(withQuestions: false))
}
#endif
