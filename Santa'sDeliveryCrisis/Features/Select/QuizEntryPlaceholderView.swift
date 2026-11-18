import SwiftUI

/// 실제 퀴즈 화면을 연결하기 전까지 전달받은 세션 정보만 보여 주는 화면.
// FIXME: [B 교체] QuizFlowView(session:)가 병합되면 이 임시 화면을 삭제하고 교체
struct QuizEntryPlaceholderView: View {
    /// 이동 대상으로 전달받은 기존 또는 새 세션.
    let session: QuizSession

    /// 작업 이름, 난이도, 문제 수와 저장된 현재 위치를 표시한다.
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LabeledContent("작업", value: session.category?.taskName ?? "작업 정보 없음")
                LabeledContent("난이도", value: session.difficulty.displayName)
                LabeledContent("문제 수", value: "\(session.questionSnapshots.count)문제")
                LabeledContent("현재 위치", value: "\(session.currentIndex)")
            }
            .font(.body)
            .foregroundStyle(Color.roomPrimaryText)
            .padding()
            .background(Color.roomCardBackground, in: RoundedRectangle(cornerRadius: 14))
            .padding()
        }
        .background(Color.roomBackground)
        .navigationTitle("세션 정보")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func quizEntryPreview(
    category: QuizCategory? = .swiftSyntax, empty: Bool = false, currentIndex: Int = 0
) -> some View {
    let session = QuizSession(
        category: category,
        difficulty: .easy,
        questionSnapshots: empty ? [] : [QuestionSnapshot(MockData.question)],
        passThresholdPercent: 80
    )
    session.currentIndex = currentIndex
    return NavigationStack {
        QuizEntryPlaceholderView(session: session)
    }
}

#Preview("퀴즈 진입 · 세션 정보") {
    quizEntryPreview()
}

#Preview("퀴즈 진입 · 작업 없음") {
    quizEntryPreview(category: nil)
}

#Preview("퀴즈 진입 · 문제 없음") {
    quizEntryPreview(empty: true)
}

#Preview("퀴즈 진입 · 다크") {
    quizEntryPreview(currentIndex: 1)
        .preferredColorScheme(.dark)
}

#Preview("퀴즈 진입 · 큰 글자") {
    quizEntryPreview()
        .dynamicTypeSize(.accessibility3)
}
