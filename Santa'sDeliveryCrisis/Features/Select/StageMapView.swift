import SwiftUI

/// 배경과 같은 좌표계에 열두 단계와 보상을 배치하는 가로 지도.
struct StageMapView: View {
    /// 현재 트리의 실제 획득 칸.
    let rewardMask: Int
    /// 화면에서 마지막으로 선택하거나 이동할 단계.
    let focusedStage: QuizStage
    /// 같은 단계로 다시 이동하는 명시적인 설정·초기화 요청.
    let focusRequestID: UUID
    /// 난이도마다 선택한 카테고리에서 준비할 수 있는 문제 수.
    let availableCounts: [Difficulty: Int]
    /// 사용자가 선택한 문제 수.
    let requestedCount: Int
    /// 화면에 표시하지 않을 때 시간 갱신을 멈춘다.
    let isAnimating: Bool
    /// 동작 줄이기에서 모든 장식을 정지 상태로 그린다.
    let reduceMotion: Bool
    /// 잠김과 후보 부족 안내는 출제 화면에서 처리한다.
    let onSelect: (QuizStage) -> Void

    /// 가운데 마을 양 끝 빈터를 안쪽으로 옮긴 지도에 맞춘 단계의 위치 비율.
    private let positions: [CGPoint] = [
        CGPoint(x: 0.071, y: 0.545), CGPoint(x: 0.116, y: 0.680),
        CGPoint(x: 0.222, y: 0.660), CGPoint(x: 0.262, y: 0.480),
        CGPoint(x: 0.380, y: 0.665), CGPoint(x: 0.415, y: 0.545),
        CGPoint(x: 0.579, y: 0.505), CGPoint(x: 0.605, y: 0.665),
        CGPoint(x: 0.748, y: 0.685), CGPoint(x: 0.793, y: 0.540),
        CGPoint(x: 0.904, y: 0.545), CGPoint(x: 0.893, y: 0.430)
    ]

    /// 한 화면에 마을 하나가 들어오도록 표시하고, 자동 이동은 선택 난이도의 마을 중앙에 맞춘다.
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 3
            let height = width / 2
            StageMapScrollView(
                contentSize: CGSize(width: width, height: height),
                focusX: CGFloat(group(focusedStage.difficulty)) / 6 * width,
                focusedStageID: focusedStage.id, focusRequestID: focusRequestID
            ) {
                TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !isAnimating || reduceMotion)) { timeline in
                    let time = isAnimating && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate : 0
                    ZStack(alignment: .topLeading) {
                        Image("SantaVillageMap")
                            .resizable()
                            .interpolation(.none)
                            .frame(width: width, height: height)
                            .accessibilityHidden(true)

                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            districtSign(difficulty)
                                .position(x: CGFloat(group(difficulty)) / 6 * width, y: 36)
                        }

                        ForEach(QuizStage.all) { stage in
                            StageMapNode(
                                stage: stage, rewardMask: rewardMask,
                                hasCandidates: (availableCounts[stage.difficulty] ?? 0) >= requestedCount,
                                time: time
                            ) { onSelect(stage) }
                            .id(stage.id)
                            // 이름표 아래를 기준으로 구슬과 발판의 두 터치 영역을 함께 배치한다.
                            .position(
                                x: positions[stage.id].x * width,
                                y: positions[stage.id].y * height - 53
                            )
                        }

                        StageMapSnow(time: time)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    .frame(width: width, height: height)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func group(_ difficulty: Difficulty) -> Int {
        QuizStage(task: .wishReception, difficulty: difficulty).groupNumber * 2 - 1
    }

    private func districtSign(_ difficulty: Difficulty) -> some View {
        VStack(spacing: 3) {
            Text(QuizStage(task: .wishReception, difficulty: difficulty).districtName)
                .font(.subheadline.weight(.heavy))
            Text(difficulty.displayName)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(Color.glowWhite)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.inkShadow.opacity(0.88), in: RoundedRectangle(cornerRadius: 4))
        .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(Color.glowGold, lineWidth: 2) }
        .fixedSize()
        .accessibilityHidden(true)
    }
}

/// 떠 있는 구슬과 대비가 강한 완료 체크·현재 위치를 표시하는 단계 버튼.
private struct StageMapNode: View {
    let stage: QuizStage
    let rewardMask: Int
    let hasCandidates: Bool
    let time: TimeInterval
    let onSelect: () -> Void

    private var isEarned: Bool { stage.isEarned(in: rewardMask) }
    private var isUnlocked: Bool { stage.isUnlocked(in: rewardMask) }
    private var isNext: Bool { QuizStage.next(in: rewardMask) == stage }

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onSelect) {
                floatingReward
                    .frame(width: 52, height: 54)
                    .contentShape(Rectangle())
            }
            .accessibilityHidden(true)

            Button(action: onSelect) {
                VStack(spacing: 4) {
                    Ellipse()
                        .fill(isNext ? Color.glowGold : Color.inkShadow.opacity(0.8))
                        .overlay { Ellipse().strokeBorder(isUnlocked ? Color.glowGold : Color.plainOrnament, lineWidth: 2) }
                        .frame(width: 38, height: 14)
                        .overlay {
                            if !isUnlocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.glowWhite)
                            }
                        }

                    Text(stage.stepName)
                        .font(.caption2.weight(.heavy))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(Color.glowWhite)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(isNext ? Color.ornamentRed : Color.inkShadow, in: RoundedRectangle(cornerRadius: 3))
                        .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(Color.glowWhite, lineWidth: 1) }
                        .opacity(isUnlocked && !hasCandidates ? 0.65 : 1)
                        .frame(maxWidth: 100)
                }
                .frame(minWidth: 52, minHeight: 44, alignment: .bottom)
                .contentShape(Rectangle())
            }
            .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default) { onSelect() }
        .accessibilityLabel("\(stage.title), \(stage.difficulty.displayName), 보상 장식 1개")
        .accessibilityValue(isEarned ? "획득 완료" : isNext ? "다음 도전" : "잠김")
        .accessibilityHint(!isUnlocked ? "앞선 단계의 장식을 먼저 획득해야 해요" : !hasCandidates ? "현재 출제 조건의 문제 수가 부족해요" : "두 번 탭하면 퀴즈를 시작해요")
    }

    /// 구슬은 길 위의 지점을 가리지 않게 떠 있고, 상태 배지와 현재 화살표를 함께 그린다.
    private var floatingReward: some View {
        ZStack(alignment: .bottomTrailing) {
            OrnamentView(style: OrnamentStyle(task: stage.task), size: 42)
                .frame(width: 48, height: 54)
                .opacity(isUnlocked ? 1 : 0.5)
                .saturation(isUnlocked ? 1 : 0.4)
                .offset(y: time == 0 ? 0 : sin(time * 2 + Double(stage.id)) * 3)

            if isEarned {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.glowWhite)
                    .padding(6)
                    .background(Color.inkShadow, in: Circle())
                    .overlay { Circle().strokeBorder(Color.glowWhite, lineWidth: 2) }
                    .offset(x: 7, y: 4)
            }
        }
        .overlay(alignment: .top) {
            if isNext {
                StagePointer()
                    .fill(Color.ornamentRed)
                    .overlay { StagePointer().stroke(Color.inkShadow, lineWidth: 5) }
                    .overlay { StagePointer().stroke(Color.glowWhite, lineWidth: 2) }
                    .frame(width: 28, height: 30)
                    .shadow(color: .inkShadow.opacity(0.7), radius: 1, y: 3)
                    .offset(y: -38 + (time == 0 ? 0 : sin(time * 3) * 3))
            }
        }
    }
}

/// 눈 위에서도 또렷한 이중 테두리 화살표의 외곽선.
private struct StagePointer: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [CGPoint] = [
            CGPoint(x: 0.30, y: 0), CGPoint(x: 0.70, y: 0),
            CGPoint(x: 0.70, y: 0.50), CGPoint(x: 1, y: 0.50),
            CGPoint(x: 0.50, y: 1), CGPoint(x: 0, y: 0.50), CGPoint(x: 0.30, y: 0.50)
        ]
        return Path { path in
            path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
            path.closeSubpath()
        }
    }
}

/// 지도 위에만 내리는 작은 눈. 정지 상태에서는 같은 위치에 머문다.
private struct StageMapSnow: View {
    let time: TimeInterval

    var body: some View {
        Canvas { context, size in
            for index in 0..<35 {
                let phase = (time / Double(5 + index % 5) + Double(index) * 0.19).truncatingRemainder(dividingBy: 1)
                let x = CGFloat((index * 31 + 7) % 100) / 100 * size.width
                let y = CGFloat(phase) * size.height
                context.fill(Path(CGRect(x: x, y: y, width: 3, height: 3)), with: .color(.glowWhite.opacity(0.75)))
            }
        }
    }
}
