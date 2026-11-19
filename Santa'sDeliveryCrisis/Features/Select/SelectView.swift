import SwiftData
import SwiftUI

/// 출제 조건 편집과 장식 선택, 세션 진입을 연결하는 화면.
struct SelectView: View {
    /// 퀴즈는 탭 전환에도 유지되는 상위 화면에서 표시한다.
    @Binding var activeQuizSession: QuizSession?

    /// 작업실에서 새 퀴즈를 요청할 때 바뀌는 값. 직접 탭 전환은 설정을 초기화하지 않는다.
    var setupRequestID: UUID? = nil

    private struct PendingStart: Identifiable {
        let id = UUID()
        let existing: QuizSession
        let filter: SelectFilter
    }

    private struct DeferredPresentation {
        let result: StartSessionCoordinator.Outcome
        let resetsFilter: Bool
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.services) private var services
    @Query private var sessions: [QuizSession]
    @Query private var questions: [Question]
    /// 작업실과 동일하게 가장 먼저 시작한 현재 트리의 장식 수를 표시한다.
    @Query(
        filter: #Predicate<TreeRecord> { $0.completedAt == nil },
        sort: \TreeRecord.startedAt
    ) private var activeTrees: [TreeRecord]
    @State private var filterState = SelectFilterState()
    @State private var isEditing = true
    @State private var pendingStart: PendingStart?
    @State private var deferredPresentation: DeferredPresentation?
    @State private var showsStartFailure = false

    /// 장식 선택 위에 설정 팝업을 표시하고 세션 처리 결과에 따라 화면을 연다.
    var body: some View {
        ZStack {
            decorationSelection
            if isEditing {
                setupOverlay
            }
        }
        .background(background)
        .onChange(of: setupRequestID) { _, _ in
            filterState = SelectFilterState()
            isEditing = true
        }
        .navigationTitle("출제")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $pendingStart, onDismiss: finishResumeChoice) { request in
            ResumeChoiceSheet(
                session: request.existing,
                onResume: {
                    completeResumeChoice(coordinator.resume(request.existing), resetsFilter: false)
                },
                onRestart: {
                    completeResumeChoice(coordinator.restart(
                        replacing: request.existing,
                        filter: request.filter, questions: questions
                    ), resetsFilter: true)
                }
            )
        }
        .alert("세션을 시작하지 못했어요", isPresented: $showsStartFailure) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("문제를 준비하는 중에 문제가 생겼어요.\n잠시 후 다시 시도해 주세요.")
        }
    }

    private var background: some View {
        // FIXME: [가정 7] 출제 탭만 나이트 색상 사용. 최종 팔레트 확정 후 정리
        LinearGradient(
            stops: [
                .init(color: .nightBackgroundTop, location: 0),
                .init(color: .nightBackgroundBottom, location: colorScheme == .dark ? 0.82 : 0.72)
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var decorationSelection: some View {
        DecorationSelectView(
            filter: filterState.applied,
            availability: DecorationAvailability.calculate(
                filter: filterState.applied, questions: questions, selector: services.selector
            ),
            filledCount: activeTrees.first?.decorationCount ?? 0,
            onEdit: beginEditing,
            onResetSettings: resetSettings,
            onSelect: { _ in startSession() }
        )
        .blur(radius: isEditing ? 5 : 0)
        .accessibilityHidden(isEditing)
        .allowsHitTesting(isEditing == false)
    }

    private var setupOverlay: some View {
        GeometryReader { geometry in
            ScrollView {
                SelectSetupPopup(
                    filter: $filterState.editing,
                    recommendedCategory: services.recommender.recommendedCategory(sessions: sessions),
                    onApply: applyEditing, onCancel: cancelEditing
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollClipDisabled()
        }
        .background {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
    }

    private var quizPresentation: Binding<QuizSession?> {
        Binding(
            get: { activeQuizSession },
            set: { session in
                // 기본 슬라이드를 끄고 QuizEntryPresentation의 페이드만 사용한다.
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    activeQuizSession = session
                }
            }
        )
    }

    private var coordinator: StartSessionCoordinator {
        StartSessionCoordinator(sessions: services.sessions, selector: services.selector)
    }

    /// 장식을 눌러 세션을 시작한다. 문제는 눌린 장식이 아니라 적용한 카테고리 전체에서 고른다.
    private func startSession() {
        guard activeQuizSession == nil, pendingStart == nil,
              deferredPresentation == nil, showsStartFailure == false else { return }
        let result = coordinator.start(filter: filterState.applied, questions: questions)
        if case .needsResumeChoice(let existing) = result {
            pendingStart = PendingStart(existing: existing, filter: filterState.applied)
        } else {
            present(result, resetsFilter: true)
        }
    }

    /// 새 세션 생성 성공일 때만 다음 출제 조건을 초기화한다. 복원·실패 시에는 유지한다.
    private func present(_ result: StartSessionCoordinator.Outcome, resetsFilter: Bool) {
        switch result {
        case .started(let session):
            if resetsFilter {
                filterState = SelectFilterState()
            }
            quizPresentation.wrappedValue = session
        case .failed:
            showsStartFailure = true
        case .needsResumeChoice:
            break
        }
    }

    private func completeResumeChoice(_ result: StartSessionCoordinator.Outcome, resetsFilter: Bool) {
        // 시트가 닫힌 뒤에 다음 화면을 열어 두 표시 요청이 겹치지 않게 한다.
        deferredPresentation = DeferredPresentation(result: result, resetsFilter: resetsFilter)
        pendingStart = nil
    }

    private func finishResumeChoice() {
        guard let presentation = deferredPresentation else { return }
        deferredPresentation = nil
        present(presentation.result, resetsFilter: presentation.resetsFilter)
    }

    private func cancelEditing() {
        filterState.cancel()
        isEditing = false
    }

    private func applyEditing() {
        filterState.apply()
        isEditing = false
    }

    private func beginEditing() {
        filterState.beginEditing()
        isEditing = true
    }

    /// 트리·장식·세션 기록은 유지하고 출제 조건만 기본값으로 되돌려 팝업을 연다.
    private func resetSettings() {
        filterState = SelectFilterState()
        isEditing = true
    }
}

#if DEBUG
/// 독립된 출제 프리뷰에서도 상위 화면이 퀴즈 표시 상태를 관리한다.
private struct SelectPreviewContent: View {
    @State private var activeQuizSession: QuizSession?

    var body: some View {
        NavigationStack { SelectView(activeQuizSession: $activeQuizSession) }
            .fullScreenCover(item: $activeQuizSession) { session in
                QuizEntryPresentation(session: session)
                    .presentationBackground(.clear)
            }
    }
}

@ViewBuilder
private func selectPreview(
    recommendedCategory: QuizCategory? = nil, existingSession: Bool = false,
    failure: FailingPreviewSessionManager.Failure? = nil
) -> some View {
    let questions = QuizCategory.allCases.flatMap { category in
        Difficulty.allCases.flatMap { difficulty in
            TaskSelectPreviewData.questions(category: category, difficulty: difficulty, count: 5)
        }
    }
    let sessions = existingSession ? [TaskSelectPreviewData.session(
        questions: questions.filter { $0.category == .swiftSyntax && $0.difficulty == .normal },
        category: .swiftSyntax, difficulty: .normal
    )] : []

    if let preview = try? TaskSelectPreviewData.environment(
        questions: questions, sessions: sessions,
        recommendedCategory: recommendedCategory, failure: failure
    ) {
        SelectPreviewContent()
            .modelContainer(preview.container)
            .environment(\.services, preview.services)
    } else {
        ContentUnavailableView(
            "미리보기 저장소를 준비하지 못했어요", systemImage: "exclamationmark.triangle"
        )
    }
}

#Preview("출제 설정 · 라이트") {
    selectPreview()
        .preferredColorScheme(.light)
}

#Preview("출제 설정 · 다크") {
    selectPreview()
        .preferredColorScheme(.dark)
}

#Preview("출제 설정 · 큰 글자") {
    selectPreview()
        .dynamicTypeSize(.accessibility5)
}

#Preview("출제 설정 · 추천 있음") {
    selectPreview(recommendedCategory: .swiftSyntax)
}

#Preview("출제 설정 · 추천 없음") {
    selectPreview(recommendedCategory: nil)
}

#Preview("출제 설정 · 적용 후 퀴즈 진입") {
    selectPreview()
}

#Preview("출제 설정 · 기존 세션 선택 흐름") {
    selectPreview(existingSession: true)
}

#Preview("출제 설정 · 신규 시작 실패") {
    selectPreview(failure: .start)
}

#Preview("출제 설정 · 재시작 생성 실패") {
    selectPreview(existingSession: true, failure: .start)
}

#Preview("출제 설정 · 기존 세션 포기 실패") {
    selectPreview(existingSession: true, failure: .abandon)
}
#endif
