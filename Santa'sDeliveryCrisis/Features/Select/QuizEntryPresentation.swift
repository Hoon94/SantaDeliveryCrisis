import SwiftData
import SwiftUI

/// 작업실·출제 화면에서 같은 퀴즈 흐름을 전체 화면으로 표시한다.
struct QuizEntryPresentation: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false

    /// 시작에 성공했거나 이어서 풀기로 선택한 세션.
    let session: QuizSession

    /// 페이드 아웃 전에 호출해 퀴즈 아래의 복귀 화면을 준비한다.
    var onWillClose: () -> Void = {}

    /// 저장된 세션으로 실제 퀴즈 흐름에 진입한다. 종료 처리는 퀴즈 화면에 맡긴다.
    var body: some View {
        QuizFlowView(session: session, onClose: close)
        .toolbar(.hidden, for: .tabBar)
        .opacity(isVisible ? 1 : 0)
        .transaction { $0.disablesAnimations = false }
        .task {
            // 동작 줄이기에서도 화면 전환은 짧은 페이드로 표시한다.
            withAnimation(.easeInOut(duration: 0.25)) {
                isVisible = true
            }
        }
    }

    private func close() {
        guard isVisible else { return }
        onWillClose()
        withAnimation(.easeInOut(duration: 0.25), completionCriteria: .logicallyComplete) {
            isVisible = false
        } completion: {
            dismiss()
        }
    }
}

#if DEBUG
@ViewBuilder
private func quizPresentationPreview() -> some View {
    let questions = TaskSelectPreviewData.questions(category: .swiftSyntax, difficulty: .normal, count: 5)
    let session = TaskSelectPreviewData.session(
        questions: questions, category: .swiftSyntax, difficulty: .normal, answered: 2
    )
    if let preview = try? TaskSelectPreviewData.environment(questions: questions, sessions: [session]) {
        QuizEntryPresentation(session: session)
            .modelContainer(preview.container)
            .environment(\.services, preview.services)
    } else {
        ContentUnavailableView("미리보기 데이터를 준비하지 못했어요", systemImage: "exclamationmark.triangle")
    }
}

#Preview("퀴즈 진입 · 페이드") {
    quizPresentationPreview()
}

#Preview("퀴즈 진입 · 페이드 다크") {
    quizPresentationPreview()
        .preferredColorScheme(.dark)
}
#endif
