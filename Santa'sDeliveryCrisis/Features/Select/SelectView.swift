import SwiftData
import SwiftUI

/// 출제 조건 편집과 스테이지 지도, 세션 진입을 연결하는 화면.
struct SelectView: View {
    /// 퀴즈는 탭 전환에도 유지되는 상위 화면에서 표시한다.
    @Binding var activeQuizSession: QuizSession?

    /// 작업실에서 새 퀴즈를 요청할 때 바뀌는 값. 직접 탭 전환은 설정을 초기화하지 않는다.
    var setupRequestID: UUID? = nil

    private struct PendingStart: Identifiable {
        let id = UUID()
        let existing: QuizSession
        let task: WorkshopTask
        let filter: SelectFilter
    }

    private struct StartRequest {
        let task: WorkshopTask
        let filter: SelectFilter
        let existing: QuizSession?
    }

    private struct DeferredPresentation {
        let result: StartSessionCoordinator.Outcome
        let resetsFilter: Bool
        let request: StartRequest
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
    @State private var pendingPractice: StartRequest?
    @State private var focusedStage = QuizStage(task: .wishReception, difficulty: .easy)
    @State private var focusRequestID = UUID()
    @State private var lockedStage: QuizStage?
    @State private var didInitializeProgress = false
    @State private var startFailureMessage = "문제를 준비하는 중에 문제가 생겼어요.\n잠시 후 다시 시도해 주세요."

    private var rewardMask: Int { activeTrees.first?.rewardMask ?? 0 }
    private var nextStage: QuizStage {
        QuizStage.next(in: rewardMask) ?? QuizStage(task: .sleighLoading, difficulty: .hard)
    }
    private var availableCounts: [Difficulty: Int] {
        Dictionary(uniqueKeysWithValues: Difficulty.allCases.map { difficulty in
            (difficulty, services.selector.availableCount(
                categories: filterState.applied.categories, difficulty: difficulty, tags: [], questions: questions
            ))
        })
    }

    /// 지도 위에 설정 팝업을 표시하고 세션 처리 결과에 따라 화면을 연다.
    var body: some View {
        ZStack {
            decorationSelection
            if isEditing {
                setupOverlay
            }
        }
        .background(background)
        .onChange(of: setupRequestID) { _, _ in
            resetFilter()
            isEditing = true
        }
        .onAppear {
            if !didInitializeProgress {
                resetFilter()
                didInitializeProgress = true
            }
        }
        .onChange(of: rewardMask) { _, _ in synchronizeProgress() }
        .onChange(of: activeTrees.first?.id) { _, _ in synchronizeProgress() }
        .navigationTitle("출제")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $pendingStart, onDismiss: finishResumeChoice) { request in
            ResumeChoiceSheet(
                session: request.existing,
                onResume: {
                    completeResumeChoice(
                        coordinator.resume(request.existing), resetsFilter: false,
                        request: StartRequest(task: request.task, filter: request.filter, existing: request.existing)
                    )
                },
                onRestart: {
                    completeResumeChoice(coordinator.restart(
                        replacing: request.existing, task: request.task,
                        filter: request.filter, questions: questions, currentTree: activeTrees.first
                    ), resetsFilter: true,
                       request: StartRequest(task: request.task, filter: request.filter, existing: request.existing))
                }
            )
        }
        .alert("이미 장식을 받은 난이도예요", isPresented: practiceConfirmation, presenting: pendingPractice) { request in
            Button("취소", role: .cancel) { pendingPractice = nil }
            Button("계속 풀기") {
                pendingPractice = nil
                performStart(request, allowsPractice: true)
            }
        } message: { request in
            Text("\(QuizStage(task: request.task, difficulty: request.filter.difficulty).title) · \(request.filter.difficulty.displayName) 장식은 이미 받았어요. 다시 풀어도 장식은 그대로이며 추가 보상은 없어요. 학습 기록은 저장돼요.")
        }
        .alert("아직 잠긴 스테이지예요", isPresented: stageLockPresentation, presenting: lockedStage) { _ in
            Button("확인") { lockedStage = nil }
        } message: { stage in
            Text("\(stage.title)에 도전하려면 앞선 단계의 장식을 먼저 획득해 주세요.")
        }
        .alert("세션을 시작하지 못했어요", isPresented: $showsStartFailure) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(startFailureMessage)
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
            filter: filterState.applied, availableCounts: availableCounts,
            rewardMask: rewardMask, focusedStage: focusedStage, focusRequestID: focusRequestID,
            isCovered: isEditing || activeQuizSession != nil,
            onEdit: beginEditing,
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
                    rewardMask: rewardMask,
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

    /// 단계 해금·기존 세션·재풀이 확인을 거쳐 선택한 보상 칸의 세션을 시작한다.
    private func startSession(stage: QuizStage) {
        guard activeQuizSession == nil, pendingStart == nil, pendingPractice == nil,
              deferredPresentation == nil, showsStartFailure == false, lockedStage == nil else { return }
        guard stage.isUnlocked(in: rewardMask) else {
            lockedStage = stage
            return
        }
        filterState.selectDifficulty(stage.difficulty)
        focus(on: stage)
        performStart(StartRequest(task: stage.task, filter: filterState.applied, existing: nil))
    }

    private var stageLockPresentation: Binding<Bool> {
        Binding(get: { lockedStage != nil }, set: { if !$0 { lockedStage = nil } })
    }

    private var practiceConfirmation: Binding<Bool> {
        Binding(get: { pendingPractice != nil }, set: { if !$0 { pendingPractice = nil } })
    }

    private func performStart(_ request: StartRequest, allowsPractice: Bool = false) {
        let result: StartSessionCoordinator.Outcome
        if let existing = request.existing {
            result = coordinator.restart(
                replacing: existing, task: request.task, filter: request.filter,
                questions: questions, currentTree: activeTrees.first, allowsPractice: allowsPractice
            )
        } else {
            result = coordinator.start(
                task: request.task, filter: request.filter, questions: questions,
                currentTree: activeTrees.first, allowsPractice: allowsPractice
            )
        }
        present(result, resetsFilter: true, request: request)
    }

    /// 새 세션 생성 성공일 때만 다음 출제 조건을 초기화한다. 복원·실패 시에는 유지한다.
    private func present(_ result: StartSessionCoordinator.Outcome, resetsFilter: Bool, request: StartRequest) {
        switch result {
        case .started(let session):
            if resetsFilter { resetFilter() }
            quizPresentation.wrappedValue = session
        case .failed:
            let count = services.selector.availableCount(
                categories: request.filter.categories, difficulty: request.filter.difficulty,
                tags: [], questions: questions
            )
            startFailureMessage = count < request.filter.count
                ? "고른 조건에는 \(count)문제만 있어요. 문제 수나 카테고리를 바꿔 보세요."
                : "문제를 준비하는 중에 문제가 생겼어요.\n잠시 후 다시 시도해 주세요."
            showsStartFailure = true
        case .locked(let stage):
            lockedStage = stage
        case .needsResumeChoice(let existing):
            pendingStart = PendingStart(existing: existing, task: request.task, filter: request.filter)
        case .needsPracticeConfirmation:
            pendingPractice = request
        }
    }

    private func completeResumeChoice(
        _ result: StartSessionCoordinator.Outcome, resetsFilter: Bool, request: StartRequest
    ) {
        // 시트가 닫힌 뒤에 다음 화면·알림을 열어 표시 요청이 겹치지 않게 한다.
        deferredPresentation = DeferredPresentation(result: result, resetsFilter: resetsFilter, request: request)
        pendingStart = nil
    }

    private func finishResumeChoice() {
        guard let presentation = deferredPresentation else { return }
        deferredPresentation = nil
        present(presentation.result, resetsFilter: presentation.resetsFilter, request: presentation.request)
    }

    private func cancelEditing() {
        filterState.cancel()
        isEditing = false
    }

    private func applyEditing() {
        let destination = QuizStage.destination(for: filterState.editing.difficulty, rewardMask: rewardMask) ?? nextStage
        filterState.editing = filterState.editing.selecting(destination.difficulty)
        filterState.apply()
        focus(on: destination)
        isEditing = false
    }

    private func beginEditing() {
        filterState.beginEditing()
        isEditing = true
    }

    /// 다음 도전의 난이도, 전체 카테고리, 5문제를 새 출제 기본값으로 사용한다.
    private func resetFilter() {
        filterState = SelectFilterState(applied: SelectFilter(difficulty: nextStage.difficulty))
        focus(on: nextStage)
    }

    /// 보상 또는 현재 트리가 바뀌면 기존 출제 조건을 보존하며 다음 도전으로 이동한다.
    private func synchronizeProgress() {
        if isEditing {
            filterState.editing = filterState.editing.selecting(nextStage.difficulty)
        } else {
            filterState.selectDifficulty(nextStage.difficulty)
        }
        focus(on: nextStage)
    }

    /// 같은 구역을 다시 선택해도 사용자가 움직인 지도 위치를 해당 지점으로 돌린다.
    private func focus(on stage: QuizStage) {
        focusedStage = stage
        focusRequestID = UUID()
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
    failure: FailingPreviewSessionManager.Failure? = nil, earnedTask: WorkshopTask? = nil, filledCount: Int = 0
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

    let tree = {
        let tree = TreeRecord()
        for stage in QuizStage.all.prefix(TreeSlots.clampedCount(filledCount)) {
            tree.recordReward(task: stage.task, difficulty: stage.difficulty)
        }
        if let earnedTask {
            tree.recordReward(task: earnedTask, difficulty: .normal)
        }
        return tree
    }()
    if let preview = try? TaskSelectPreviewData.environment(
        questions: questions, sessions: sessions, trees: [tree],
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
#Preview("출제 · 11개 획득 · 썰매 적재 어려움으로 완성") {
    selectPreview(filledCount: 11)
}

#Preview("출제 · 이미 보상 획득 · 재풀이 확인") {
    selectPreview(earnedTask: .giftProduction)
}

#Preview("출제 · 기존 세션 교체 전 재풀이 확인 취소") {
    selectPreview(existingSession: true, earnedTask: .giftProduction)
}
#endif
