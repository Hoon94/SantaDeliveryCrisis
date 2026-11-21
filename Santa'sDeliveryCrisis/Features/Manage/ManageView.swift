import SwiftData
import SwiftUI

/// 문제 관리 화면(S10). 문제를 검색하고 작업·난이도로 거르며, 내가 만든 문제를 고치거나 지운다.
/// 기본(시드) 문제와 애니메이션 문제의 [수정]/[삭제]는 흐리게 표시하고 반응하지 않는다.
struct ManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.services) private var services
    @Query(sort: \Question.createdAt, order: .reverse) private var questions: [Question]

    @State private var searchText = ""
    @State private var category: QuizCategory?
    @State private var difficulty: Difficulty?
    @State private var editTarget: EditTarget?
    @State private var pendingDelete: Question?
    @State private var errorMessage: String?
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 38

    /// 편집 화면으로 보낼 대상
    private enum EditTarget: Hashable {
        case new
        case existing(UUID)
        /// 읽기 전용 상세 화면. 기본 문제와 내 문제 모두 연다.
        case detail(UUID)
    }

    var body: some View {
        VStack(spacing: 12) {
            ManageSearchField(text: $searchText)
            ManageFilterBar(category: $category, difficulty: $difficulty)
            if filteredQuestions.isEmpty {
                ScrollView { emptyState }
            } else {
                questionList
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color.roomPrimaryText)
        .background(Color.roomBackground)
        .toolbarBackground(Color.roomBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar { ManageToolbar { editTarget = .new } }
        .navigationDestination(item: $editTarget) { target in
            destination(for: target)
        }
        .alert("이 문제를 삭제할까요?", isPresented: isDeleteAlertPresented, presenting: pendingDelete) { question in
            Button("취소", role: .cancel) { pendingDelete = nil }
            Button("삭제", role: .destructive) { delete(question) }
        } message: { question in
            Text("“\(question.text)”가 새 출제 대상과 오답 노트에서 사라져요. 이미 끝난 문제의 점수는 그대로예요.")
        }
        .alert("문제를 삭제하지 못했어요", isPresented: isErrorPresented) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - 목록

    private var questionList: some View {
        List {
            Section {
                ForEach(filteredQuestions) { question in
                    QuestionRow(
                        question: question,
                        onOpen: { editTarget = .detail(question.id) },
                        onEdit: { editTarget = .existing(question.id) },
                        onDelete: { pendingDelete = question }
                    )
                    .listRowBackground(Color.roomCardBackground)
                    .listRowSeparatorTint(Color.roomBorder)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // 내가 만든 일반 문제에만 스와이프 삭제를 붙인다.
                        if isEditable(question) {
                            Button("삭제", role: .destructive) { pendingDelete = question }
                                .tint(Color.roomNegative)
                        }
                    }
                }
            } footer: {
                if filteredQuestions.contains(where: { !isEditable($0) }) {
                    Text("🔒 기본 문제는 수정할 수 없어요")
                        .font(.caption)
                        .foregroundStyle(Color.roomSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(.compact)
        .padding(.horizontal, -16)
    }

    // MARK: - 빈 상태

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🗂")
                .font(.system(size: emptyIconSize))
                .accessibilityHidden(true)
            Text(questions.isEmpty ? "아직 문제가 없어요" : "조건에 맞는 문제가 없어요")
                .font(.headline)
            Text(questions.isEmpty ? "새 문제를 만들어 보세요" : "필터를 초기화하거나 새 문제를 만들어 보세요")
                .font(.subheadline)
                .foregroundStyle(Color.roomSecondaryText)
                .multilineTextAlignment(.center)
            if !questions.isEmpty {
                Button(action: resetFilters) {
                    Text("필터 초기화")
                        .font(.body.bold())
                        .foregroundStyle(Color.roomAccent)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.roomAccent, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            Button { editTarget = .new } label: {
                Text("＋ 새 문제 만들기")
                    .font(.body.bold())
                    .foregroundStyle(Color.roomOnAccentText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.roomAccent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.top, questions.isEmpty ? 8 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - 거르기

    private var filteredQuestions: [Question] {
        let keyword = QuestionDraft.trimmed(searchText)
        return questions.filter { question in
            (category == nil || question.category == category)
                && (difficulty == nil || question.difficulty == difficulty)
                && (keyword.isEmpty || question.text.localizedStandardContains(keyword))
        }
    }

    private func resetFilters() {
        searchText = ""
        category = nil
        difficulty = nil
    }

    /// 내가 만든 일반 문제인지. 기본 문제와 애니메이션 문제는 고치거나 지울 수 없다.
    private func isEditable(_ question: Question) -> Bool {
        !question.isSeed && question.kind == .standard
    }

    // MARK: - 이동과 삭제

    @ViewBuilder
    private func destination(for target: EditTarget) -> some View {
        switch target {
        case .new:
            QuestionEditView(question: nil)
        case .detail(let id):
            if let question = questions.first(where: { $0.id == id }) {
                QuestionDetailView(question: question)
            } else {
                ContentUnavailableView(
                    "문제를 찾을 수 없어요",
                    systemImage: "exclamationmark.triangle",
                    description: Text("삭제되었을 수 있어요.")
                )
            }
        case .existing(let id):
            if let question = questions.first(where: { $0.id == id }), isEditable(question) {
                QuestionEditView(question: question)
            } else {
                ContentUnavailableView(
                    "문제를 열 수 없어요",
                    systemImage: "exclamationmark.triangle",
                    description: Text("삭제되었거나 수정할 수 없는 문제예요.")
                )
            }
        }
    }

    private func delete(_ question: Question) {
        let editor = QuestionEditor(context: modelContext, media: services.media)
        do {
            try editor.delete(question)
        } catch QuestionEditorError.seedQuestion {
            errorMessage = "기본 문제는 삭제할 수 없어요."
        } catch QuestionEditorError.animationQuestion {
            errorMessage = "애니메이션 문제는 삭제할 수 없어요."
        } catch {
            errorMessage = "잠시 후 다시 시도해 주세요."
        }
        pendingDelete = nil
    }

    private var isDeleteAlertPresented: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }
}

/// 문제 관리 화면의 상단 막대. 왼쪽 위에 "문제 관리", 오른쪽 위에 [＋]을 둔다.
/// 가운데 제목은 비워 둔다.
private struct ManageToolbar: ToolbarContent {
    let onAdd: () -> Void

    var body: some ToolbarContent {
        // 폭을 0으로 줄여, 가운데 항목이 공간을 차지해 왼쪽 글자가 "..."로 잘리는 일을 막는다.
        ToolbarItem(placement: .principal) {
            Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
        }
        if #available(iOS 26.0, *) {
            // iOS 26은 툴바 항목마다 둥근 배경을 입히므로 제목에서는 숨긴다.
            ToolbarItem(placement: .topBarLeading) { title }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { title }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .foregroundStyle(Color.roomAccent)
            }
            .accessibilityLabel("새 문제")
        }
    }

    private var title: some View {
        Text("문제 관리")
            .font(.title2.bold())
            .foregroundStyle(Color.roomPrimaryText)
            .lineLimit(1)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
#Preview("문제 있음") {
    NavigationStack { ManageView() }
        .modelContainer(ManagePreviewData.container(withQuestions: true))
}

#Preview("문제 없음") {
    NavigationStack { ManageView() }
        .modelContainer(ManagePreviewData.container(withQuestions: false))
}
#endif
