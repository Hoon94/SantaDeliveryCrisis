import SwiftUI

/// 작업실 배경과 진행 칩 위에 공통 트리를 표시하는 영역.
struct TaskTreePanel: View {
    /// 표시할 장식 수.
    let filledCount: Int

    /// 크기 제한 없이 부모의 남은 공간을 채우는 트리 영역.
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                let design = TreeSlots.designSize
                let scale = min(geometry.size.width / design.width, geometry.size.height / design.height)
                let sceneSize = CGSize(width: design.width * scale, height: design.height * scale)

                ZStack {
                    roomScene(scale: scale, size: sceneSize)
                    ChristmasTreeImage(filledCount: filledCount)
                }
                .frame(width: sceneSize.width, height: sceneSize.height)
                .position(x: geometry.size.width / 2, y: geometry.size.height - sceneSize.height / 2)
            }
            .accessibilityHidden(true)

            progressChip
                .padding(10)
        }
        .background(Color.roomWall)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var progressChip: some View {
        (
            Text("🎄 ")
            + Text("\(TreeSlots.clampedCount(filledCount))").foregroundColor(.roomAccent)
            + Text(" / \(TreeSlots.count)")
        )
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.roomPrimaryText)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.roomCardBackground, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.roomBorder))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("장식 \(TreeSlots.clampedCount(filledCount))/\(TreeSlots.count)")
    }

    // FIXME: [자산 교체] 임시 도형으로 그린 작업실 바닥과 창문을 실제 작업실 배경 이미지로 교체
    private func roomScene(scale: CGFloat, size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.roomFloor)
                .frame(width: size.width, height: 44 * scale)
                .offset(y: 170 * scale)

            RoundedRectangle(cornerRadius: 3 * scale)
                .fill(Color.roomWindow)
                .overlay {
                    RoundedRectangle(cornerRadius: 3 * scale)
                        .strokeBorder(Color.roomFloor, lineWidth: 3 * scale)
                }
                .overlay {
                    Path { path in
                        path.move(to: CGPoint(x: 22 * scale, y: 0))
                        path.addLine(to: CGPoint(x: 22 * scale, y: 50 * scale))
                        path.move(to: CGPoint(x: 0, y: 25 * scale))
                        path.addLine(to: CGPoint(x: 44 * scale, y: 25 * scale))
                    }
                    .stroke(Color.roomFloor, lineWidth: 2 * scale)
                }
                .frame(width: 44 * scale, height: 50 * scale)
                .offset(x: 8 * scale, y: 30 * scale)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

#Preview("트리 영역") {
    TaskTreePanel(filledCount: 6)
}
