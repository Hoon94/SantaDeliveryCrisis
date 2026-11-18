import SwiftData
import SwiftUI

/// 기록 대시보드(S9). 주/월 단위로 시도 횟수, 평균 점수, 풀이 문제 수, 취약 카테고리, 완성한 트리 수를 보여 준다.
/// 끝낸(`completed`) 세션만 집계한다.
struct RecordsView: View {
    /// 빈 상태의 [문제풀러 가기]를 눌렀을 때 출제 탭으로 이동시키는 동작. 탭 구성(`MainTabView`)이 넘겨 준다.
    var onGoToSelect: (() -> Void)?

    @Query private var sessions: [QuizSession]
    /// 완성한 트리. 트리가 완성되면 화면이 바로 갱신되도록 서비스 호출 대신 직접 관찰한다.
    @Query(filter: #Predicate<TreeRecord> { $0.completedAt != nil })
    private var completedTrees: [TreeRecord]
    @State private var period: RecordsPeriod = .week
    /// 빈 상태 아이콘 크기. 시안은 38이고 글자 크기 설정에 따라 함께 커진다.
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 38

    private let statistics = RecordsStatistics()

    var body: some View {
        let summary = statistics.summary(sessions: sessions, period: period)
        let hasAnyRecord = sessions.contains { $0.status == .completed }
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                RoomSegmentedControl(
                    options: RecordsPeriod.allCases.map { ($0, $0.displayName, $0.displayName) },
                    selection: $period
                )
                if !hasAnyRecord {
                    // 끝낸 세션이 한 번도 없을 때
                    emptyState(
                        title: "아직 기록이 없어요",
                        message: "세션을 한 번 마치면\n여기에서 통계를 볼 수 있어요",
                        topPadding: 80
                    )
                } else {
                    RecordsSummaryCards(
                        attemptCount: summary.attemptCount,
                        averageScore: summary.averageScore,
                        completedTreeCount: completedTrees.count
                    )
                    if summary.isEmpty {
                        // 다른 기간에는 기록이 있지만 선택한 기간에는 없을 때
                        emptyState(
                            title: "이 기간에는 기록이 없어요",
                            message: "다른 기간을 고르거나\n새 문제를 풀어 보세요",
                            topPadding: 24
                        )
                    } else {
                        SolvedCountChart(days: summary.days, period: period)
                        WeakCategoryList(categories: summary.weakCategories)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.roomText)
        .background(Color.roomBackground)
        .toolbarBackground(Color.roomBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar { RecordsToolbar() }
    }

    /// 기록이 없을 때의 안내. `topPadding`으로 위쪽 간격을 조절한다.
    private func emptyState(title: String, message: String, topPadding: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text("📊")
                .font(.system(size: emptyIconSize))
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.roomSub)
                .multilineTextAlignment(.center)
            if let onGoToSelect {
                Button(action: onGoToSelect) {
                    Text("문제풀러 가기")
                        .font(.body.bold())
                        .foregroundStyle(Color.roomOnAccent)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.roomAccent, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, topPadding)
    }
}

/// 기록 화면의 상단 막대. 왼쪽 위에 "기록", 오른쪽 위에 "⚙ 설정"을 둔다.
/// 가운데 제목은 비우고, 뒤로 가기 이름에는 탭 루트의 제목("기록")이 쓰인다.
private struct RecordsToolbar: ToolbarContent {
    var body: some ToolbarContent {
        // 폭을 0으로 줄여, 가운데 항목이 공간을 차지해 왼쪽 글자가 "..."로 잘리는 일을 막는다.
        ToolbarItem(placement: .principal) {
            Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
        }
        if #available(iOS 26.0, *) {
            // iOS 26은 툴바 항목마다 둥근 배경을 입히므로 제목에서는 숨긴다.
            ToolbarItem(placement: .topBarLeading) { title }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { title }
        }
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                SettingsView()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color.roomAccent)
            }
            .accessibilityLabel("설정")
        }
    }

    private var title: some View {
        Text("기록")
            .font(.title2.bold())
            .foregroundStyle(Color.roomText)
            .lineLimit(1)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
#Preview("기록 있음") {
    NavigationStack { RecordsView() }
        .modelContainer(RecordsPreviewData.container(withSessions: true))
}

#Preview("기록 없음") {
    NavigationStack { RecordsView(onGoToSelect: {}) }
        .modelContainer(RecordsPreviewData.container(withSessions: false))
}

#Preview("선택한 기간에만 기록 없음") {
    NavigationStack { RecordsView(onGoToSelect: {}) }
        .modelContainer(RecordsPreviewData.container(withSessions: true, ageInDays: 60))
}
#endif
