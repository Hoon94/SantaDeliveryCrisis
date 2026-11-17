import SwiftUI

/// 진행 중인 세션의 작업과 답한 수를 보여 주고 같은 세션으로 이동하는 카드.
struct TaskResumeCard: View {
    /// 이어서 풀 대상인 진행 중 세션.
    let session: QuizSession

    /// 작업별 아이콘과 진행 정보를 표시하는 이동 링크.
    var body: some View {
        NavigationLink {
            QuizEntryPlaceholderView(session: session)
                // FIXME: [B 교체] 실제 퀴즈 전체 화면 연결 전까지 목적지에서 탭 바만 숨김
                .toolbar(.hidden, for: .tabBar)
        } label: {
            HStack(spacing: 10) {
                Text(taskEmoji)
                    .font(.title3)
                    .padding(8)
                    .background(Color.roomSoft, in: RoundedRectangle(cornerRadius: 11))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("이어서 풀기")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.roomText)
                    Text("\(taskName) · \(session.difficulty.displayName) · \(session.answers.count) / \(session.questionSnapshots.count) 문제")
                        .font(.caption)
                        .foregroundStyle(Color.roomSubText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

                Text("›")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Color.roomAccent)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.roomCard, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.roomAccent, lineWidth: 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("이어서 풀기, \(taskName), \(session.difficulty.displayName), 전체 \(session.questionSnapshots.count)문제 중 \(session.answers.count)문제 답함")
    }

    private var taskName: String {
        session.category?.taskName ?? "작업 정보 없음"
    }

    private var taskEmoji: String {
        switch session.category {
        case .aiUsage: "📮"
        case .swiftSyntax: "🎁"
        case .hig: "🎀"
        case .swiftUIPractice: "🛷"
        case nil: "🎁"
        }
    }
}

#Preview("이어서 풀기 · 작업 없음") {
    NavigationStack {
        TaskResumeCard(session: QuizSession(
            category: nil, difficulty: .normal, questionSnapshots: [], passThresholdPercent: 80
        ))
        .padding()
        .background(Color.roomBackground)
    }
}
