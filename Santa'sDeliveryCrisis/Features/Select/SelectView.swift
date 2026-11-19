import SwiftData
import SwiftUI

/// 출제 조건 편집과 장식 선택, 세션 진입을 연결하는 화면.
struct SelectView: View {
    private struct PendingStart: Identifiable {
        let id = UUID()
        let existing: QuizSession
        let category: QuizCategory
        let filter: SelectFilter
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.services) private var services
    @Query private var sessions: [QuizSession]
    @Query private var questions: [Question]
    @State private var filterState = SelectFilterState()
    @State private var isEditing = true
    @State private var activeQuizSession: QuizSession?
    @State private var pendingStart: PendingStart?
    @State private var deferredOutcome: StartSessionCoordinator.Outcome?
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
        .navigationTitle("출제")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ScreenTitleToolbar(title: "출제", color: .nightPrimaryText)
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: beginEditing) {
                    Image(systemName: "slider.horizontal.3")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.nightAccent)
                }
                .disabled(isEditing)
                .accessibilityLabel("출제 설정")
                .accessibilityHint("출제 설정 팝업을 다시 엽니다")
            }
        }
        .fullScreenCover(item: quizPresentation) { session in
            QuizEntryPresentation(session: session)
                .presentationBackground(.clear)
        }
        .sheet(item: $pendingStart, onDismiss: finishResumeChoice) { request in
            ResumeChoiceSheet(
                session: request.existing,
                onResume: { completeResumeChoice(coordinator.resume(request.existing)) },
                onRestart: {
                    completeResumeChoice(coordinator.restart(
                        replacing: request.existing, category: request.category,
                        filter: request.filter, questions: questions
                    ))
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
            onSelect: startSession
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
                // 팝업 내부의 빈 영역은 바깥 취소 버튼으로 탭을 전달하지 않는다.
                .contentShape(Rectangle())
                .onTapGesture {}
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .background {
                    Button(action: cancelEditing) {
                        Color.clear.contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("출제 설정 취소하고 닫기")
                }
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

    private func startSession(category: QuizCategory) {
        guard activeQuizSession == nil, pendingStart == nil,
              deferredOutcome == nil, showsStartFailure == false else { return }
        let result = coordinator.start(
            category: category, filter: filterState.applied, questions: questions
        )
        if case .needsResumeChoice(let existing) = result {
            pendingStart = PendingStart(existing: existing, category: category, filter: filterState.applied)
        } else {
            present(result)
        }
    }

    private func present(_ result: StartSessionCoordinator.Outcome) {
        switch result {
        case .started(let session):
            quizPresentation.wrappedValue = session
        case .failed:
            showsStartFailure = true
        case .needsResumeChoice:
            break
        }
    }

    private func completeResumeChoice(_ result: StartSessionCoordinator.Outcome) {
        // 시트가 닫힌 뒤에 다음 화면을 열어 두 표시 요청이 겹치지 않게 한다.
        deferredOutcome = result
        pendingStart = nil
    }

    private func finishResumeChoice() {
        guard let result = deferredOutcome else { return }
        deferredOutcome = nil
        present(result)
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
}

#if DEBUG
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
        NavigationStack { SelectView() }
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
