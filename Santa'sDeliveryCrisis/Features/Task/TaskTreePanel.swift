import Foundation
import SwiftUI

/// 픽셀 작업실과 공방 장인 산타 위에 실제 장식 진행도를 표시하는 영역.
struct TaskTreePanel: View {
    /// 장식이 날아올 칸의 화면 위치를 알려 주는 연출 상태.
    @Environment(\.rewardFlight) private var rewardFlight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false

    /// 표시할 장식 수. 비행 중인 장식의 숨김은 부모 화면에서 반영한다.
    let filledCount: Int

    /// 실제 보상을 받은 작업의 획득 순서. 결과·비행 장식과 같은 작업 색을 사용한다.
    var ornamentTasks: [WorkshopTask] = []

    /// 프리뷰에서 정지 상태를 확인한다. 시스템의 동작 줄이기 설정도 항상 우선한다.
    var forceReduceMotion = false

    private var shouldReduceMotion: Bool { reduceMotion || forceReduceMotion }

    /// 픽셀 배경의 트리 중심에 맞추는 가로 보정. 장식과 비행 좌표에 동일하게 적용한다.
    private let treeOffsetRatio: CGFloat = 0.11
    /// 아래쪽 장식이 나무 밑으로 처지지 않도록 배치 영역을 줄이고 위로 올린다.
    private let treeHeightRatio: CGFloat = 0.9
    private let treeTopOffsetRatio: CGFloat = -0.045

    /// 이미지 비율을 유지하면서 부모가 제공하는 패널을 빈틈없이 채운다.
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                let side = max(geometry.size.width, geometry.size.height)

                ZStack(alignment: .topLeading) {
                    Image("PixelWorkshopRoom")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: side, height: side)

                    PixelArtisanSanta(isAnimating: isVisible && scenePhase == .active && !shouldReduceMotion)
                        .frame(width: side * 0.36, height: side * 0.48)
                        .offset(y: side * 0.43)

                    ornaments
                        .frame(width: side, height: side * treeHeightRatio)
                        .offset(x: side * treeOffsetRatio, y: side * treeTopOffsetRatio)
                }
                .frame(width: side, height: side)
                // 장식에 적용한 보정 영역을 비행 연출의 도착 좌표에도 전달한다.
                .onGeometryChange(for: CGRect.self) { proxy in
                    let frame = proxy.frame(in: .global)
                    return CGRect(
                        x: frame.minX + frame.width * treeOffsetRatio,
                        y: frame.minY + frame.height * treeTopOffsetRatio,
                        width: frame.width,
                        height: frame.height * treeHeightRatio
                    )
                } action: { rewardFlight.treeSceneFrame = $0 }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .accessibilityHidden(true)

            progressChip
                .padding(10)
        }
        .background(Color.roomWall)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private var progressChip: some View {
        (
            Text("🎄 ")
            + Text("\(TreeSlots.clampedCount(filledCount))").foregroundColor(.roomAccent)
            + Text(" / \(TreeSlots.count)")
        )
        .font(.caption.weight(.bold))
        .contentTransition(.numericText())
        .animation(shouldReduceMotion ? nil : .snappy, value: filledCount)
        .foregroundStyle(Color.roomPrimaryText)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.roomCardBackground, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.roomBorder))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("장식 \(TreeSlots.clampedCount(filledCount))/\(TreeSlots.count)")
    }

    /// 조합별 위치가 아니라 기존처럼 획득 개수만큼 위에서 아래로 채운다.
    private var ornaments: some View {
        Canvas { context, size in
            let scale = size.width / TreeSlots.designSize.width
            for (index, point) in TreeSlots.positions.enumerated() {
                let center = CGPoint(x: point.x * size.width, y: point.y * size.height)
                let isFilled = index < TreeSlots.clampedCount(filledCount)
                let radius = (isFilled ? 7.0 : 6.0) * scale
                let shape = ornamentPath(center: center, radius: radius)

                if isFilled {
                    // 획득 기록이 없는 프리뷰·개발 데이터는 임의의 작업 색을 만들지 않는다.
                    let color = ornamentTasks.indices.contains(index) ? ornamentTasks[index].themeColor : Color.plainOrnament
                    context.fill(shape, with: .color(color))
                    context.stroke(shape, with: .color(.glowCore), lineWidth: scale)
                    context.fill(
                        Path(CGRect(x: center.x - 3 * scale, y: center.y - 3 * scale,
                                    width: 3 * scale, height: 3 * scale)),
                        with: .color(.glowCore)
                    )
                } else {
                    context.stroke(
                        shape, with: .color(.glowCore.opacity(0.6)),
                        style: StrokeStyle(lineWidth: scale, dash: [2 * scale, 2 * scale])
                    )
                }
            }
        }
    }

    /// 픽셀 그림에 맞춰 네 모서리를 한 계단씩 깎은 장식 외곽선.
    private func ornamentPath(center: CGPoint, radius: CGFloat) -> Path {
        let step = radius / 3
        let points: [CGPoint] = [
            CGPoint(x: -radius + step, y: -radius), CGPoint(x: radius - step, y: -radius),
            CGPoint(x: radius - step, y: -radius + step), CGPoint(x: radius, y: -radius + step),
            CGPoint(x: radius, y: radius - step), CGPoint(x: radius - step, y: radius - step),
            CGPoint(x: radius - step, y: radius), CGPoint(x: -radius + step, y: radius),
            CGPoint(x: -radius + step, y: radius - step), CGPoint(x: -radius, y: radius - step),
            CGPoint(x: -radius, y: -radius + step), CGPoint(x: -radius + step, y: -radius + step)
        ]
        return Path { path in
            path.addLines(points.map { CGPoint(x: center.x + $0.x, y: center.y + $0.y) })
            path.closeSubpath()
        }
    }
}

/// 가로로 나열된 네 자세를 순서대로 보여 주는 공방 장인 산타.
private struct PixelArtisanSanta: View {
    let isAnimating: Bool
    private let poses = [0, 0, 1, 2, 2, 1, 3, 3, 0, 0]

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 0.4, paused: !isAnimating)) { timeline in
                let phase = Int(timeline.date.timeIntervalSinceReferenceDate / 0.4) % poses.count
                let pose = isAnimating ? poses[phase] : 0

                Image("PixelWorkshopArtisanSanta")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: geometry.size.width * 4, height: geometry.size.height)
                    .offset(x: -CGFloat(pose) * geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                    .clipped()
            }
        }
        .allowsHitTesting(false)
    }
}

#if DEBUG
#Preview("픽셀 작업실 · 빈 트리 · 라이트") {
    TaskTreePanel(filledCount: 0)
        .aspectRatio(1, contentMode: .fit)
        .preferredColorScheme(.light)
}

#Preview("픽셀 작업실 · 장식 6개") {
    TaskTreePanel(
        filledCount: 6,
        ornamentTasks: [.wishReception, .giftProduction, .wrapping, .sleighLoading, .giftProduction, .wrapping]
    )
    .aspectRatio(1, contentMode: .fit)
}

#Preview("픽셀 작업실 · 완성 · 다크") {
    TaskTreePanel(
        filledCount: TreeSlots.count,
        ornamentTasks: WorkshopTask.allCases.flatMap { Array(repeating: $0, count: 3) }
    )
    .aspectRatio(1, contentMode: .fit)
    .preferredColorScheme(.dark)
}

#Preview("픽셀 작업실 · 동작 줄이기") {
    TaskTreePanel(
        filledCount: 6,
        ornamentTasks: [.wishReception, .giftProduction, .wrapping, .sleighLoading, .giftProduction, .wrapping],
        forceReduceMotion: true
    )
    .aspectRatio(1, contentMode: .fit)
}
#endif
