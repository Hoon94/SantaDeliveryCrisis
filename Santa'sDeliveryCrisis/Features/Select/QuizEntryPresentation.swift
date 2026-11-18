import SwiftUI

/// 실제 퀴즈 화면 연결 전 세션 정보를 전체 화면 페이드로 표시한다.
// FIXME: [B 교체] QuizFlowView(session:)가 병합되면 임시 세션 화면과 닫기 UI를 실제 흐름으로 교체
struct QuizEntryPresentation: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false

    /// 시작에 성공했거나 이어서 풀기로 선택한 세션.
    let session: QuizSession

    /// 탭 바 없는 독립된 화면에 세션 정보를 표시한다.
    var body: some View {
        NavigationStack {
            QuizEntryPlaceholderView(session: session)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("닫기", action: close)
                            .accessibilityHint("세션을 유지하고 장식 선택 화면으로 돌아갑니다")
                    }
                }
        }
        .toolbar(.hidden, for: .tabBar)
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

#Preview("퀴즈 진입 · 페이드") {
    QuizEntryPresentation(session: MockData.session())
}

#Preview("퀴즈 진입 · 페이드 다크") {
    QuizEntryPresentation(session: MockData.session())
        .preferredColorScheme(.dark)
}
