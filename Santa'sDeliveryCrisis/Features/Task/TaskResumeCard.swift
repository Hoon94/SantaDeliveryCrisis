import SwiftUI

/// 오늘의 출제와 같은 강조 스타일로 진행 중인 세션을 이어 푸는 버튼.
struct TaskResumeCard: View {
    /// 이어서 풀 대상인 진행 중 세션.
    let session: QuizSession

    /// 학습 시작 버튼 위치에서 작업과 진행 정보를 표시하고 같은 세션으로 이동한다.
    var body: some View {
        NavigationLink(value: session.id) {
            VStack(spacing: 4) {
                Text("이어서 풀기")
                    .font(.body.weight(.heavy))
                Text("\(taskName) · \(session.difficulty.displayName) · \(session.answers.count) / \(session.questionSnapshots.count) 문제")
                    .font(.caption)
                    .opacity(0.85)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(14)
            .foregroundStyle(Color.roomOnAccentText)
            .background(Color.roomAccent, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("이어서 풀기, \(taskName), \(session.difficulty.displayName), 전체 \(session.questionSnapshots.count)문제 중 \(session.answers.count)문제 답함")
    }

    private var taskName: String {
        session.category?.taskName ?? "작업 정보 없음"
    }
}

#if DEBUG
#Preview("이어서 풀기 · 작업 없음") {
    let session = QuizSession(
        category: nil, difficulty: .normal, questionSnapshots: [], passThresholdPercent: 80
    )
    NavigationStack {
        TaskResumeCard(session: session)
        .padding()
        .background(Color.roomBackground)
        .navigationDestination(for: UUID.self) { _ in
            QuizEntryPlaceholderView(session: session)
        }
    }
}
#endif
