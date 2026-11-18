import SwiftUI

/// 진행 중인 세션을 이어 풀거나 새로 시작하도록 선택하는 나이트 시트.
struct ResumeChoiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsRestartConfirmation = false
    @State private var isResolving = false

    /// 이어서 풀 수 있는 기존 세션.
    let session: QuizSession

    /// 기존 세션을 그대로 이어 푸는 동작.
    let onResume: () -> Void

    /// 파괴적 확인을 마친 뒤 기존 세션을 포기하고 새로 시작하는 동작.
    let onRestart: () -> Void

    /// 세션 정보와 두 선택 버튼을 표시하고 확인 취소 시 시트를 유지한다.
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("진행 중인 세션이 있어요")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.nightPrimaryText)
                        .accessibilityAddTraits(.isHeader)

                    HStack(spacing: 10) {
                        Text(taskEmoji)
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

                    Button {
                        guard isResolving == false else { return }
                        isResolving = true
                        onResume()
                    } label: {
                        Text("이어서 풀기")
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .foregroundStyle(Color.nightOnAccentText)
                            .background(Color.nightAccent, in: Capsule())
                    }

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
                .font(.body.weight(.bold))
                .buttonStyle(.plain)
                .disabled(isResolving)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .background(Color.nightCardBackground)
        .presentationBackground(Color.nightCardBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isResolving)
        .accessibilityAction(.escape, closeWithoutChoosing)
        .accessibilityAction(named: Text("선택하지 않고 닫기"), closeWithoutChoosing)
        .alert("새로 시작할까요?", isPresented: $showsRestartConfirmation) {
            Button("취소", role: .cancel) {}
            Button("새로 시작", role: .destructive) {
                guard isResolving == false else { return }
                isResolving = true
                onRestart()
            }
        } message: {
            Text("진행 중이던 세션(\(taskName) · \(session.difficulty.displayName) \(session.answers.count)/\(session.questionSnapshots.count))은\n이어서 풀 수 없게 돼요.")
        }
    }

    private var taskName: String { session.category?.taskName ?? "작업 정보 없음" }

    private var taskEmoji: String {
        switch session.category {
        case .aiUsage: "📮"
        case .swiftSyntax: "🎁"
        case .hig: "🎀"
        case .swiftUIPractice: "🛷"
        case nil: "🎁"
        }
    }

    private func closeWithoutChoosing() {
        guard isResolving == false else { return }
        dismiss()
    }
}

private struct ResumeChoiceSheetPreview: View {
    var category: QuizCategory? = .swiftSyntax
    @State private var isPresented = true

    var body: some View {
        let snapshots = (0..<10).map { index in
            QuestionSnapshot(Question(
                text: "이어서 풀기 시트 미리보기 \(index + 1)", choices: ["하나", "둘", "셋", "넷"],
                correctIndex: 0, explanation: "미리보기 해설",
                category: category ?? .swiftSyntax, difficulty: .normal
            ))
        }
        let session = QuizSession(
            category: category, difficulty: .normal, questionSnapshots: snapshots,
            passThresholdPercent: 80
        )
        session.answers = snapshots.prefix(6).map {
            SessionAnswer(questionID: $0.questionID, selectedIndex: 0, isCorrect: true)
        }
        session.currentIndex = session.answers.count
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
