import SwiftUI

/// 공통 트리에 적용하는 화면별 색상 구성.
enum TreeSkin {
    /// 작업실의 초록 트리 색상.
    case room
    /// 출제 탭의 나이트 글로우 트리 색상.
    // FIXME: [가정 7] 출제 탭만 나이트 글로우 색을 쓰는 가정. 최종 색이 하나로 정해지면 스킨 분기를 정리
    case night
}

/// 장식 진행도를 정적으로 그리는 공통 트리.
// FIXME: [자산 교체] 임시 도형(삼각형, 원)으로 그린 트리와 장식을 실제 트리/장식 이미지로 교체
struct TreeView: View {
    /// 채워진 장식 수. 표시할 때 모델의 유효 범위로 보정한다.
    let filledCount: Int
    /// 트리에 적용할 화면별 색상.
    var skin: TreeSkin = .room

    /// 부모 공간에 맞춰 원본 비율을 유지하는 트리 그림.
    var body: some View {
        Canvas { context, size in
            let design = TreeSlots.designSize
            let scale = min(size.width / design.width, size.height / design.height)
            context.translateBy(
                x: (size.width - design.width * scale) / 2,
                y: (size.height - design.height * scale) / 2
            )
            context.scaleBy(x: scale, y: scale)

            context.fill(
                polygon([(110, 34), (76, 98), (144, 98)]),
                with: .color(skin == .room ? .treeTier3 : .nightTreeTier3)
            )
            context.fill(
                polygon([(110, 62), (60, 140), (160, 140)]),
                with: .color(skin == .room ? .treeTier2 : .nightTreeTier2)
            )
            context.fill(
                polygon([(110, 96), (46, 184), (174, 184)]),
                with: .color(skin == .room ? .treeTier1 : .nightTreeTier1)
            )
            context.fill(
                Path(roundedRect: CGRect(x: 100, y: 184, width: 20, height: 20), cornerRadius: 2),
                with: .color(skin == .room ? .treeTrunk : .nightTreeTrunk)
            )
            context.fill(
                polygon([
                    (110, 14), (114, 25), (126, 25), (116, 32), (120, 44),
                    (110, 37), (100, 44), (104, 32), (94, 25), (106, 25)
                ]),
                with: .color(.treeStar)
            )

            let ornamentColors: [Color] = [
                .ornament1, .ornament2, .ornament3,
                .ornament4, .ornament5, .ornament6
            ]
            for (index, position) in TreeSlots.positions.enumerated() {
                let center = CGPoint(x: position.x * design.width, y: position.y * design.height)
                if index < TreeSlots.clampedCount(filledCount) {
                    let circle = Path(ellipseIn: CGRect(
                        x: center.x - 7, y: center.y - 7, width: 14, height: 14
                    ))
                    context.fill(circle, with: .color(ornamentColors[index % ornamentColors.count]))
                    context.stroke(circle, with: .color(.treeHighlight), lineWidth: 1.5)
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - 2 - 1.8, y: center.y - 2 - 1.8,
                            width: 3.6, height: 3.6
                        )),
                        with: .color(Color.treeHighlight.opacity(0.8))
                    )
                } else {
                    let radius: CGFloat = 6
                    let circle = Path(ellipseIn: CGRect(
                        x: center.x - radius, y: center.y - radius,
                        width: radius * 2, height: radius * 2
                    ))
                    context.stroke(
                        circle,
                        with: .color(Color.treeHighlight.opacity(0.75)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                    )
                }
            }
        }
        .aspectRatio(TreeSlots.designSize.width / TreeSlots.designSize.height, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("장식 \(TreeSlots.clampedCount(filledCount))/\(TreeSlots.count)")
    }

    private func polygon(_ coordinates: [(CGFloat, CGFloat)]) -> Path {
        Path { path in
            guard let first = coordinates.first else { return }
            path.move(to: CGPoint(x: first.0, y: first.1))
            for coordinate in coordinates.dropFirst() {
                path.addLine(to: CGPoint(x: coordinate.0, y: coordinate.1))
            }
            path.closeSubpath()
        }
    }
}

#Preview("작업실 · 빈 트리") {
    TreeView(filledCount: 0)
        .background(Color.appBackground)
        .preferredColorScheme(.light)
}

#Preview("작업실 · 장식 6개") {
    TreeView(filledCount: 6)
        .background(Color.appBackground)
        .preferredColorScheme(.light)
}

#Preview("작업실 · 완성") {
    TreeView(filledCount: TreeSlots.count)
        .background(Color.appBackground)
        .preferredColorScheme(.light)
}

#Preview("나이트 · 장식 6개") {
    TreeView(filledCount: 6, skin: .night)
        .background(Color.nightBackgroundTop)
        .preferredColorScheme(.light)
}

#Preview("나이트 · 다크") {
    TreeView(filledCount: 6, skin: .night)
        .background(Color.nightBackgroundTop)
        .preferredColorScheme(.dark)
}
