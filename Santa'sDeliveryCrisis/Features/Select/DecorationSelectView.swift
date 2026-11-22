import SwiftUI

/// 기존 출제 제목·설정·진행도 아래에 산타 마을 스테이지 지도를 표시한다.
struct DecorationSelectView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false

    /// 마지막으로 적용한 출제 설정.
    let filter: SelectFilter
    /// 선택한 카테고리의 난이도별 후보 수.
    let availableCounts: [Difficulty: Int]
    /// 현재 트리의 실제 보상 칸.
    let rewardMask: Int
    /// 지도에서 중앙에 맞출 단계.
    let focusedStage: QuizStage
    /// 설정 적용·초기화 등 같은 위치로 돌아가는 요청.
    let focusRequestID: UUID
    /// 설정 팝업이나 퀴즈가 지도를 덮을 때는 시간 갱신을 멈춘다.
    let isCovered: Bool
    /// 기존 설정 팝업을 연다.
    let onEdit: () -> Void
    /// 선택한 단계의 잠금·후보·기존 세션을 확인한 뒤 시작한다.
    let onSelect: (QuizStage) -> Void
    /// 프리뷰에서 시스템 설정과 별개로 정지 상태를 확인한다.
    var forceReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || forceReduceMotion }
    private var filledCount: Int { rewardMask.nonzeroBitCount }

    /// 지도는 남은 공간에 맞추되 터치 간격이 필요한 작은 화면에서는 세로 스크롤을 허용한다.
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 14) {
                    header
                    Text("열린 스테이지를 눌러 퀴즈를 시작하세요")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.nightSecondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if dynamicTypeSize.isAccessibilitySize {
                        accessibleStages
                    } else {
                        StageMapView(
                            rewardMask: rewardMask, focusedStage: focusedStage, focusRequestID: focusRequestID,
                            availableCounts: availableCounts, requestedCount: filter.count,
                            isAnimating: isVisible && scenePhase == .active && !isCovered,
                            reduceMotion: reduceMotion, onSelect: onSelect
                        )
                        // 2:1 지도에서 마을 하나의 가로 폭은 전체의 1/3이므로 표시 비율은 2:3이다.
                        .frame(height: max(geometry.size.width - 28, 0) * 1.5)
                    }

                    if let count = availableCounts[filter.difficulty], count < filter.count {
                        Text("고른 조건에는 \(count)문제만 있어요. 문제 수나 카테고리를 바꿔 보세요")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.nightPrimaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("장식 12개를 모아 작업실 트리를 완성해요")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.nightSecondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))

        return VStack(alignment: .leading, spacing: 8) {
            Text("출제")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.nightPrimaryText)
                .accessibilityAddTraits(.isHeader)

            layout {
                conditionChip
                if dynamicTypeSize.isAccessibilitySize == false {
                    Spacer(minLength: 0)
                }
                decorationProgress
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var conditionChip: some View {
        Button(action: onEdit) {
            Label(
                "\(filter.difficulty.displayName) · 카테고리 \(filter.categories.count)개 · \(filter.count)문제",
                systemImage: "gearshape"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.nightOnAccentText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Color.nightAccent, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("출제 설정, \(filter.difficulty.displayName), 카테고리 \(filter.categories.count)개, \(filter.count)문제")
        .accessibilityHint("문제 유형 선택 팝업을 다시 엽니다")
    }

    private var decorationProgress: some View {
        Text("\(TreeSlots.clampedCount(filledCount)) / \(TreeSlots.count) 장식")
            .font(.caption.weight(.heavy))
            .foregroundStyle(Color.nightPrimaryText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Color.nightCardBackground, in: Capsule())
            .overlay { Capsule().strokeBorder(Color.nightBorder, lineWidth: 1) }
            .accessibilityLabel("장식 \(TreeSlots.count)개 중 \(TreeSlots.clampedCount(filledCount))개 획득")
    }

    /// 큰 글자에서는 지도를 작은 글자로 축소하지 않고 열두 단계를 목록으로 표시한다.
    private var accessibleStages: some View {
        VStack(spacing: 10) {
            ForEach(QuizStage.all) { stage in
                let earned = stage.isEarned(in: rewardMask)
                let unlocked = stage.isUnlocked(in: rewardMask)
                Button { onSelect(stage) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: earned ? "checkmark.circle.fill" : unlocked ? "arrow.right.circle.fill" : "lock.fill")
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stage.title).font(.headline)
                            Text("\(stage.difficulty.displayName) · \(earned ? "장식 획득 완료" : unlocked ? "다음 도전" : "잠김")")
                                .font(.body)
                            if (availableCounts[stage.difficulty] ?? 0) < filter.count {
                                Text("출제 후보 부족").font(.caption)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Color.nightPrimaryText)
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .background(Color.nightCardBackground, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint(unlocked ? "퀴즈 시작" : "앞선 단계의 장식을 먼저 획득해야 해요")
            }
        }
    }
}

#if DEBUG
/// 실제 보상 비트를 단계 순서로 구성하는 지도 표시 전용 프리뷰.
private struct StageMapPreview: View {
    var earnedCount = 0
    var sparseRewards = false
    var forceReduceMotion = false
    var insufficientCandidates = false
    private let focusRequestID = UUID()

    private var rewardMask: Int {
        var mask = QuizStage.all.prefix(earnedCount).reduce(0) { $0 | $1.task.rewardBit(for: $1.difficulty) }
        if sparseRewards { mask |= WorkshopTask.wrapping.rewardBit(for: .hard) }
        return mask
    }

    var body: some View {
        let stage = QuizStage.next(in: rewardMask) ?? QuizStage(task: .sleighLoading, difficulty: .hard)
        DecorationSelectView(
            filter: SelectFilter(difficulty: stage.difficulty),
            availableCounts: [.easy: insufficientCandidates ? 0 : 15, .normal: 15, .hard: 15],
            rewardMask: rewardMask, focusedStage: stage, focusRequestID: focusRequestID,
            isCovered: false, onEdit: {}, onSelect: { _ in },
            forceReduceMotion: forceReduceMotion
        )
        .background(Color.nightBackgroundTop)
    }
}

#Preview("스테이지 · 처음 시작") { StageMapPreview() }
#Preview("스테이지 · 쉬움 진행") { StageMapPreview(earnedCount: 2) }
#Preview("스테이지 · 보통 해금") { StageMapPreview(earnedCount: 4) }
#Preview("스테이지 · 어려움 해금") { StageMapPreview(earnedCount: 8) }
#Preview("스테이지 · 마지막 장식 직전") { StageMapPreview(earnedCount: 11) }
#Preview("스테이지 · 기존 비순차 보상 보존") { StageMapPreview(earnedCount: 1, sparseRewards: true) }
#Preview("스테이지 · 후보 없음") { StageMapPreview(insufficientCandidates: true) }
#Preview("스테이지 · 동작 줄이기") { StageMapPreview(forceReduceMotion: true) }
#Preview("스테이지 · 라이트") { StageMapPreview(earnedCount: 4).preferredColorScheme(.light) }
#Preview("스테이지 · 다크") { StageMapPreview(earnedCount: 4).preferredColorScheme(.dark) }
#Preview("스테이지 · 큰 글자") { StageMapPreview().dynamicTypeSize(.accessibility5) }
#Preview("스테이지 · iPad", traits: .fixedLayout(width: 1024, height: 768)) { StageMapPreview(earnedCount: 8) }
#endif
