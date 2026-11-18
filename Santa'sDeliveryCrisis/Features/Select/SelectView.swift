import SwiftData
import SwiftUI

/// 흐려진 나이트 트리 위에서 출제 조건을 편집하는 화면.
struct SelectView: View {
    private enum Phase {
        case editing, applied
    }

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
    @State private var phase: Phase = .editing
    @State private var activeQuizSession: QuizSession?
    @State private var startOutcome: StartSessionCoordinator.Outcome?
    @State private var pendingStart: PendingStart?
    @State private var deferredOutcome: StartSessionCoordinator.Outcome?
    @State private var showsStartFailure = false
    private let recommender: any TaskRecommending
    private let selector: (any QuestionSelecting)?

    /// 추천기를 주입받으며 실제 서비스 연결 전 기본값은 추천 없는 임시 구현이다.
    init(
        recommender: any TaskRecommending = TempTaskRecommender(),
        selector: (any QuestionSelecting)? = nil
    ) {
        self.recommender = recommender
        self.selector = selector
    }

    /// 나이트 배경과 중앙 팝업을 표시하고 편집 중인 출제 조건을 연결한다.
    var body: some View {
        // FIXME: [가정 2] 추천 계산은 추천기에 위임하며 화면은 반환된 카테고리만 표시
        let recommendedCategory = recommender.recommendedCategory(sessions: sessions)
        let availability = DecorationAvailability.calculate(
            filter: filterState.applied, questions: questions, selector: selector ?? services.selector
        )
        // FIXME: [가정 7] 출제 탭만 나이트 글로우 색 사용. 최종 색이 정해지면 정리
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: .nightBackgroundTop, location: 0),
                        .init(color: .nightBackgroundBottom, location: colorScheme == .dark ? 0.82 : 0.72)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                DecorationSelectView(
                    filter: filterState.applied, availability: availability,
                    onEdit: beginEditing, onSelect: startSession
                )
                .blur(radius: phase == .editing ? 5 : 0)
                .accessibilityHidden(phase == .editing)
                .allowsHitTesting(phase == .applied)

                if phase == .editing {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)

                    ScrollView {
                        ZStack {
                            Button(action: cancelEditing) {
                                Color.clear.contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("출제 설정 취소하고 닫기")

                            SelectSetupPopup(
                                filter: $filterState.editing,
                                recommendedCategory: recommendedCategory,
                                onApply: applyEditing,
                                onCancel: cancelEditing
                            )
                            // 팝업 내부의 빈 영역은 바깥 취소 버튼으로 탭을 전달하지 않는다.
                            .onTapGesture {}
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                    .scrollClipDisabled()
                }
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

    private var quizPresentation: Binding<QuizSession?> {
        Binding(
            get: { activeQuizSession },
            set: { session in
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    activeQuizSession = session
                }
            }
        )
    }

    private func startSession(category: QuizCategory) {
        guard activeQuizSession == nil, pendingStart == nil, showsStartFailure == false else { return }
        let result = coordinator.start(
            category: category, filter: filterState.applied, questions: questions
        )
        recordOutcome(result)
        if case .needsResumeChoice(let existing) = result {
            pendingStart = PendingStart(existing: existing, category: category, filter: filterState.applied)
        }
    }

    private var coordinator: StartSessionCoordinator {
        StartSessionCoordinator(sessions: services.sessions, selector: selector ?? services.selector)
    }

    private func recordOutcome(_ result: StartSessionCoordinator.Outcome) {
        startOutcome = result
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
        deferredOutcome = result
        pendingStart = nil
    }

    private func finishResumeChoice() {
        guard let result = deferredOutcome else { return }
        deferredOutcome = nil
        recordOutcome(result)
    }

    // FIXME: [가정 4] 바깥 탭과 접근성 닫기는 편집을 취소하고 마지막 적용값을 유지
    private func cancelEditing() {
        filterState.cancel()
        phase = .applied
    }

    private func applyEditing() {
        filterState.apply()
        phase = .applied
    }

    private func beginEditing() {
        filterState.beginEditing()
        phase = .editing
    }
}

@ViewBuilder
private func selectPreview(
    recommender: any TaskRecommending = TempTaskRecommender(), existingSession: Bool = false,
    failure: FailingPreviewSessionManager.Failure? = nil
) -> some View {
    if let container = try? selectPreviewContainer(),
       let previewServices = try? selectPreviewServices(existingSession: existingSession, failure: failure) {
        NavigationStack { SelectView(recommender: recommender, selector: PreviewQuestionSelector()) }
            .modelContainer(container)
            .environment(\.services, previewServices)
    } else {
        ContentUnavailableView(
            "미리보기 저장소를 준비하지 못했어요", systemImage: "exclamationmark.triangle"
        )
    }
}

private func selectPreviewServices(
    existingSession: Bool, failure: FailingPreviewSessionManager.Failure?
) throws -> AppServices {
    let source = AppServices.preview
    let sessions = MockSessionManager()
    if existingSession {
        _ = try sessions.startSession(category: .swiftSyntax, difficulty: .normal, tags: [], count: 5)
    }
    let sessionManager: any SessionManaging
    if let failure {
        sessionManager = FailingPreviewSessionManager(base: sessions, failure: failure)
    } else {
        sessionManager = sessions
    }
    return AppServices(
        settings: source.settings, selector: PreviewQuestionSelector(),
        sessions: sessionManager, trees: source.trees,
        feedback: source.feedback, media: source.media, traceScenes: source.traceScenes
    )
}

private func selectPreviewContainer() throws -> ModelContainer {
    let container = try ModelContainerFactory.make(inMemory: true)
    for category in QuizCategory.allCases {
        for difficulty in Difficulty.allCases {
            for index in 0..<5 {
                container.mainContext.insert(Question(
                    text: "출제 전환 미리보기 \(index + 1)", choices: ["하나", "둘", "셋", "넷"],
                    correctIndex: 0, explanation: "미리보기 해설",
                    category: category, difficulty: difficulty
                ))
            }
        }
    }
    try container.mainContext.save()
    return container
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
    selectPreview(recommender: TempTaskRecommender(category: .swiftSyntax))
}

#Preview("출제 설정 · 추천 없음") {
    selectPreview(recommender: TempTaskRecommender(category: nil))
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
