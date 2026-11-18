import SwiftUI

/// 크리스마스트리 이미지와 작업실의 장식 진행도를 표시한다.
struct ChristmasTreeImage: View {
    /// 값이 있으면 작업실의 장식 칸을 표시하고, 없으면 이미지 자체만 표시한다.
    var filledCount: Int? = nil

    /// 투명 여백을 포함한 이미지의 표시 배율. 화면별로 트리 크기를 조절한다.
    var imageScale: CGFloat = 1.4

    /// 기존 트리 좌표계에 이미지와 장식을 함께 맞춘다.
    var body: some View {
        GeometryReader { geometry in
            let design = TreeSlots.designSize
            let scale = min(geometry.size.width / design.width, geometry.size.height / design.height)
            let sceneSize = CGSize(width: design.width * scale, height: design.height * scale)

            // 장식의 기준 영역은 고정하고 이미지 확대가 레이아웃 크기에 영향을 주지 않게 한다.
            Color.clear
                .frame(width: sceneSize.width, height: sceneSize.height)
                .overlay {
                    Image("ChristmasTree")
                        .resizable()
                        .scaledToFit()
                        // 이미지의 투명 여백을 보정해 기존 장식 좌표 안에 트리를 배치한다.
                        .frame(
                            width: sceneSize.width * imageScale,
                            height: sceneSize.height * imageScale
                        )
                        .offset(y: 8 * scale)
                }
                .overlay {
                    if let filledCount {
                        ornaments(filledCount: filledCount)
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(TreeSlots.designSize.width / TreeSlots.designSize.height, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if let filledCount {
            return "장식 \(TreeSlots.clampedCount(filledCount))/\(TreeSlots.count)"
        }
        return "크리스마스트리"
    }

    private func ornaments(filledCount: Int) -> some View {
        Canvas { context, size in
            let scale = size.width / TreeSlots.designSize.width
            let colors: [Color] = [
                .ornament1, .ornament2, .ornament3,
                .ornament4, .ornament5, .ornament6
            ]
            for (index, point) in TreeSlots.positions.enumerated() {
                let center = CGPoint(x: point.x * size.width, y: point.y * size.height)
                let isFilled = index < TreeSlots.clampedCount(filledCount)
                let radius: CGFloat = (isFilled ? 7 : 6) * scale
                let circle = Path(ellipseIn: CGRect(
                    x: center.x - radius, y: center.y - radius,
                    width: radius * 2, height: radius * 2
                ))
                if isFilled {
                    context.fill(circle, with: .color(colors[index % colors.count]))
                    context.stroke(circle, with: .color(.treeHighlight), lineWidth: 1.5 * scale)
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - 3.8 * scale, y: center.y - 3.8 * scale,
                            width: 3.6 * scale, height: 3.6 * scale
                        )),
                        with: .color(Color.treeHighlight.opacity(0.8))
                    )
                } else {
                    context.stroke(
                        circle,
                        with: .color(Color.treeHighlight.opacity(0.75)),
                        style: StrokeStyle(lineWidth: 1.5 * scale, dash: [3 * scale, 3 * scale])
                    )
                }
            }
        }
    }
}

#Preview("이미지 트리") {
    ChristmasTreeImage()
        .background(Color.roomBackground)
}

#Preview("이미지 트리 · 장식 6개") {
    ChristmasTreeImage(filledCount: 6)
        .background(Color.roomBackground)
}
