import SwiftData
import SwiftUI

/// 문제 상세 화면. 문제 관리 목록에서 문제를 누르면 열린다.
/// 사용자 일반 문제는 더보기 메뉴에서 수정·삭제할 수 있고, 기본·애니메이션 문제는 읽기만 가능하다.
/// 구성은 편집 화면과 같고, 편집 화면에서는 따로 열던 해설·힌트·학습 자료·태그를 화면 안에 바로 보여 준다.
struct QuestionDetailView: View {
    let question: Question

    @Environment(\.services) private var services
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var showsDeleteConfirmation = false
    @State private var errorMessage: String?

    private static let choiceLabels = ["A", "B", "C", "D"]

    private var isEditable: Bool { !question.isSeed && question.kind == .standard }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                textCard(title: "문제", text: question.text, isEmphasized: true)
                if let code = nonEmpty(question.codeSnippet) { codeCard(code) }
                mediaSection
                choicesCard
                infoRow(title: "카테고리", value: question.category.categoryName)
                infoRow(title: "난이도", value: question.difficulty.displayName)
                textCard(title: "해설", text: question.explanation.isEmpty ? "해설이 없어요" : question.explanation)
                if let hint = nonEmpty(question.hint) { textCard(title: "힌트", text: hint) }
                resourceCard
                if !question.tags.isEmpty { textCard(title: "태그", text: question.tags.joined(separator: ", ")) }
                if !isEditable { lockedNotice }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.roomPrimaryText)
        .background(Color.roomBackground)
        .navigationTitle("문제 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Color.roomBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    .disabled(!isEditable)

                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                    .disabled(!isEditable)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.roomAccent)
                }
                .accessibilityLabel("문제 더보기")
            }
        }
        .navigationDestination(isPresented: $isEditing) {
            QuestionEditView(question: question)
        }
        .alert("이 문제를 삭제할까요?", isPresented: $showsDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive, action: deleteQuestion)
        } message: {
            Text("“\(question.text)”가 새 출제 대상과 오답 노트에서 사라져요. 이미 끝난 문제의 점수는 그대로예요.")
        }
        .alert("문제를 삭제하지 못했어요", isPresented: isErrorPresented) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - 삭제

    /// 삭제 저장까지 성공한 경우에만 상세 화면을 닫는다. 실패하면 상세와 오류 안내를 유지한다.
    private func deleteQuestion() {
        let editor = QuestionEditor(context: modelContext, media: services.media)
        do {
            try editor.delete(question)
            dismiss()
        } catch QuestionEditorError.seedQuestion {
            errorMessage = "기본 문제는 삭제할 수 없어요."
        } catch QuestionEditorError.animationQuestion {
            errorMessage = "애니메이션 문제는 삭제할 수 없어요."
        } catch {
            errorMessage = "잠시 후 다시 시도해 주세요."
        }
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    // MARK: - 카드

    /// 제목 한 줄과 본문을 카드로 보여 준다. 글자를 길게 눌러 복사할 수 있다.
    private func textCard(title: String, text: String, isEmphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)
            Text(text)
                .font(isEmphasized ? .subheadline.bold() : .subheadline)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .roomCardBackground(padding: EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12))
        .accessibilityElement(children: .combine)
    }

    /// 문제에 딸린 코드. 코드 문제는 제목만으로는 무엇을 묻는지 알 수 없어서 함께 보여 준다.
    private func codeCard(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("코드")
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .roomCardBackground(padding: EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12))
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(Color.roomSecondaryText)
        }
        .font(.subheadline)
        .roomCardBackground(padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        .accessibilityElement(children: .combine)
    }

    // MARK: - 보기

    private var choicesCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                if index > 0 { Divider().overlay(Color.roomBorder) }
                choiceRow(index: index, text: choice)
            }
        }
        .roomCardBackground(padding: EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
    }

    private func choiceRow(index: Int, text: String) -> some View {
        let label = Self.choiceLabels.indices.contains(index) ? Self.choiceLabels[index] : "\(index + 1)"
        let isCorrect = index == question.correctIndex
        return HStack(alignment: .top, spacing: 10) {
            // 정답은 색뿐 아니라 아이콘과 "정답" 글자로도 구분한다.
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isCorrect ? Color.roomPositive : Color.roomSecondaryText)
                .frame(minWidth: 32)
                .padding(.vertical, 10)
                .accessibilityHidden(true)
            Text("\(label).")
                .font(.subheadline)
                .foregroundStyle(Color.roomSecondaryText)
                .padding(.top, 12)
            Text(text)
                .font(.subheadline)
                .textSelection(.enabled)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            if isCorrect {
                Text("정답")
                    .font(.caption.bold())
                    .foregroundStyle(Color.roomPositive)
                    .padding(.top, 14)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("보기 \(label), \(text)\(isCorrect ? ", 정답" : "")")
    }

    // MARK: - 미디어

    @ViewBuilder
    private var mediaSection: some View {
        if let fileName = nonEmpty(question.imageFileName) {
            VStack(alignment: .leading, spacing: 2) {
                Text("이미지")
                    .font(.caption)
                    .foregroundStyle(Color.roomSecondaryText)
                imagePreview(fileName: fileName)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .roomCardBackground(padding: EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12))
        }
        if nonEmpty(question.videoFileName) != nil {
            // 큰 영상은 미리 불러오지 않는다. 첨부되어 있다는 표시만 한다.
            Label("영상이 첨부된 문제예요", systemImage: "film")
                .font(.subheadline)
                .foregroundStyle(Color.roomSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .roomCardBackground(padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        }
    }

    @ViewBuilder
    private func imagePreview(fileName: String) -> some View {
        if let provider = services.media as? MediaURLProviding {
            AsyncImage(url: provider.url(for: fileName)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Image(systemName: "photo").foregroundStyle(Color.roomSecondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: 240)
            .accessibilityLabel("문제에 첨부된 이미지")
        } else {
            Label("이미지가 첨부된 문제예요", systemImage: "photo")
                .font(.subheadline)
                .foregroundStyle(Color.roomSecondaryText)
        }
    }

    // MARK: - 학습 자료

    @ViewBuilder
    private var resourceCard: some View {
        let title = nonEmpty(question.resourceTitle)
        let address = nonEmpty(question.resourceURL)
        if title != nil || address != nil {
            VStack(alignment: .leading, spacing: 2) {
                Text("학습 자료")
                    .font(.caption)
                    .foregroundStyle(Color.roomSecondaryText)
                if let url = webURL(address) {
                    Link(title ?? address ?? "", destination: url)
                        .font(.subheadline)
                        .tint(Color.roomAccent)
                        .accessibilityHint("Safari에서 학습 자료를 엽니다")
                } else {
                    Text(title ?? address ?? "")
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .roomCardBackground(padding: EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12))
        }
    }

    // MARK: - 안내와 도우미

    private var lockedNotice: some View {
        Label(
            question.isSeed ? "기본 문제는 수정·삭제할 수 없어요" : "애니메이션 문제는 수정·삭제할 수 없어요",
            systemImage: "lock.fill"
        )
            .font(.footnote)
            .foregroundStyle(Color.roomSecondaryText)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    /// 앞뒤 공백을 지우고, 비어 있으면 nil
    private func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        return QuestionDraft.nilIfEmpty(value)
    }

    /// http 또는 https 주소만 링크로 연다.
    private func webURL(_ address: String?) -> URL? {
        guard let address,
              let components = URLComponents(string: address),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty
        else { return nil }
        return components.url
    }
}

#if DEBUG
#Preview("내 문제") {
    let container = ManagePreviewData.container(withQuestions: false)
    let question = ManagePreviewData.sampleUserQuestion()
    container.mainContext.insert(question)
    return NavigationStack { QuestionDetailView(question: question) }
        .modelContainer(container)
}

#Preview("기본 문제(코드 포함)") {
    let container = ManagePreviewData.container(withQuestions: false)
    let question = ManagePreviewData.sampleSeedQuestion()
    container.mainContext.insert(question)
    return NavigationStack { QuestionDetailView(question: question) }
        .modelContainer(container)
}

#Preview("내 문제 · 다크 · 큰 글자") {
    let container = ManagePreviewData.container(withQuestions: false)
    let question = ManagePreviewData.sampleUserQuestion()
    container.mainContext.insert(question)
    return NavigationStack { QuestionDetailView(question: question) }
        .modelContainer(container)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
#endif
