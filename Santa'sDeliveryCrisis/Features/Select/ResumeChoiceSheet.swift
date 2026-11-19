import SwiftUI

/// 진행 중인 세션을 이어 풀거나, 포기 확인 후 새로 시작하는 선택 시트.
struct ResumeChoiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsRestartConfirmation = false
    @State private var isResolving = false
    @State private var contentHeight: CGFloat = 320

    /// 이어서 풀 수 있는 기존 세션.
    let session: QuizSession
    /// 기존 세션을 그대로 이어 푸는 동작.
    let onResume: () -> Void
    /// 포기 확인 후 기존 세션을 교체하는 동작. 실제 포기는 호출자가 처리한다.
    let onRestart: () -> Void

    /// 세션 요약과 선택 버튼을 표시한다. 큰 글자는 시트 안에서 스크롤한다.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("진행 중인 세션이 있어요")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.nightPrimaryText)
                    .accessibilityAddTraits(.isHeader)

                sessionSummary
                resumeButton
                restartButton
            }
            .font(.body.weight(.bold))
            .buttonStyle(.plain)
            .disabled(isResolving)
            .padding(.top, 44)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height.rounded(.up)
            } action: { height in
                guard height > 0 else { return }
                contentHeight = height
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .background(Color.nightCardBackground)
        .presentationBackground(Color.nightCardBackground)
        .presentationDetents([.height(contentHeight), .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isResolving)
        .accessibilityAction(.escape, closeWithoutChoosing)
        .accessibilityAction(named: Text("선택하지 않고 닫기"), closeWithoutChoosing)
        .alert("새로 시작할까요?", isPresented: $showsRestartConfirmation) {
            Button("취소", role: .cancel) {}
            Button("새로 시작", role: .destructive) { resolve(onRestart) }
        } message: {
            Text("진행 중이던 세션(\(taskName) · \(session.difficulty.displayName) \(session.answers.count)/\(session.questionSnapshots.count))은\n이어서 풀 수 없게 돼요.")
        }
        .tint(.primary)
    }

    private var sessionSummary: some View {
        HStack(spacing: 10) {
            Text(session.category?.taskEmoji ?? "🎁")
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(taskName) · \(session.difficulty.displayName)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.nightPrimaryText)
                Text("\(session.answers.count) / \(session.questionSnapshots.count) 문제까지 풀었어요")
                    .font(.caption)
                    .foregroundStyle(Color.nightSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.nightSubtleBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private var resumeButton: some View {
        Button {
            resolve(onResume)
        } label: {
            Text("이어서 풀기")
                .frame(maxWidth: .infinity)
                .padding(14)
                .foregroundStyle(Color.nightOnAccentText)
                .background(Color.nightAccent, in: Capsule())
        }
    }

    private var restartButton: some View {
        Button {
            showsRestartConfirmation = true
        } label: {
            Text("새로 시작")
                .frame(maxWidth: .infinity)
                .padding(14)
                .foregroundStyle(Color.nightPrimaryText)
                .overlay { Capsule().strokeBorder(Color.nightBorder, lineWidth: 1) }
        }
    }

    private var taskName: String { session.category?.taskName ?? "여러 카테고리 섞음" }

    private func resolve(_ action: () -> Void) {
        guard isResolving == false else { return }
        isResolving = true
        action()
    }

    private func closeWithoutChoosing() {
        guard isResolving == false else { return }
        dismiss()
    }
}

#if DEBUG
private struct ResumeChoiceSheetPreview: View {
    var category: QuizCategory? = .swiftSyntax
    @State private var isPresented = true

    var body: some View {
        let session = TaskSelectPreviewData.session(
            questions: TaskSelectPreviewData.questions(
                category: category ?? .swiftSyntax, difficulty: .normal, count: 10
            ),
            category: category, difficulty: .normal, answered: 6
        )
        return Color.nightBackgroundTop
            .ignoresSafeArea()
            .sheet(isPresented: $isPresented) {
                ResumeChoiceSheet(
                    session: session,
                    onResume: { isPresented = false },
                    onRestart: { isPresented = false }
                )
            }
    }
}

#Preview("진행 중 세션 · 선택과 재시작 확인") {
    ResumeChoiceSheetPreview()
}

#Preview("진행 중 세션 · 다크") {
    ResumeChoiceSheetPreview()
        .preferredColorScheme(.dark)
}

#Preview("진행 중 세션 · 큰 글자") {
    ResumeChoiceSheetPreview()
        .dynamicTypeSize(.accessibility5)
}

#Preview("진행 중 세션 · 작업 정보 없음") {
    ResumeChoiceSheetPreview(category: nil)
}
#endif
