import SwiftUI

/// 세션을 전체 화면 퀴즈 흐름(`QuizFlowView`)으로 연다. 열고 닫을 때 페이드를 쓴다.
struct QuizEntryPresentation: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false

    /// 시작에 성공했거나 이어서 풀기로 선택한 세션.
    let session: QuizSession

    /// 탭 바 없는 독립된 전체 화면에서 퀴즈를 진행한다. ✕나 [돌아가기]를 누르면 페이드로 닫는다.
    var body: some View {
        QuizFlowView(session: session, onClose: close)
            .opacity(isVisible ? 1 : 0)
            .transaction { $0.disablesAnimations = false }
            .task {
                // FIXME: [가정 6] 1차 전환은 모션 줄이기에서도 페이드만 사용. 확대 연출은 추후 결정
                withAnimation(.easeInOut(duration: 0.25)) {
                    isVisible = true
                }
            }
    }

    private func close() {
        guard isVisible else { return }
        withAnimation(.easeInOut(duration: 0.25), completionCriteria: .logicallyComplete) {
            isVisible = false
        } completion: {
            dismiss()
        }
    }
}

#if DEBUG
#Preview("퀴즈 진입 · 페이드") {
    QuizEntryPresentation(session: MockData.session())
}

#Preview("퀴즈 진입 · 페이드 다크") {
    QuizEntryPresentation(session: MockData.session())
        .preferredColorScheme(.dark)
}
#endif
