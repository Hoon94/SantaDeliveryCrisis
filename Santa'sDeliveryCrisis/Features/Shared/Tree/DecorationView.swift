import SwiftUI

/// 출제 화면에서 작업 이름과 선택 가능 상태를 보여 주는 정적 장식.
/// 글로우는 뷰 영역 밖으로 번지므로, 부모가 이 뷰를 `clipped()` 등으로 자르거나 `ScrollView`로 감쌀 때는 글로우가 잘릴 수 있다(스크롤 영역에서는 `scrollClipDisabled()`를 쓴다).
// FIXME: [자산 교체] 임시 도형으로 그린 구슬을 실제 장식 이미지로 교체
struct DecorationView: View {
    /// 금색 캡을 포함한 장식의 기준 크기.
    static let designSize = CGSize(width: 84, height: 94)

    /// 장식이 나타내는 작업.
    let task: WorkshopTask
    /// 눌러서 시작할 수 있는 상태. 카테고리를 선택했어도 후보가 부족하면 false다.
    let isLit: Bool

    /// 부모 공간에 맞춰 원본 비율을 유지하는 장식.
    var body: some View {
        GeometryReader { geometry in
            let scale = min(
                geometry.size.width / Self.designSize.width,
                geometry.size.height / Self.designSize.height
            )
            // 캡을 포함한 원본 세로 범위(-52...42)의 중앙은 -5다.
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2 + 5 * scale
            )

            ZStack {
                RoundedRectangle(cornerRadius: 3 * scale)
                    .fill(Color.decorationCap)
                    .frame(width: 14 * scale, height: 11 * scale)
                    .position(x: center.x, y: center.y - 46.5 * scale)

                Circle()
                    .fill(task.themeColor)
                    .frame(width: 84 * scale, height: 84 * scale)
                    .shadow(color: task.themeColor, radius: (isLit ? 22 : 9) * scale)
                    .position(center)

                Ellipse()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 24 * scale, height: 14 * scale)
                    .position(x: center.x - 15 * scale, y: center.y - 24 * scale)

                Text(task.displayName)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
                    // 글자 영역의 네 모서리도 반지름 42 안에 들어오도록 제한한다.
                    .frame(width: 68 * scale, height: 36 * scale)
                    .clipped()
                    .position(x: center.x, y: center.y + 6 * scale)
            }
            .opacity(isLit ? 1 : 0.3)
        }
        .aspectRatio(Self.designSize.width / Self.designSize.height, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(task.displayName), \(isLit ? "켜짐" : "꺼짐")")
    }
}

#if DEBUG
#Preview("네 작업 · 켜짐") {
    VStack(spacing: 44) {
        ForEach(WorkshopTask.allCases, id: \.self) { task in
            DecorationView(task: task, isLit: true)
        }
    }
    .padding(30)
    .background(Color.nightBackgroundTop)
}

#Preview("네 작업 · 꺼짐") {
    VStack(spacing: 44) {
        ForEach(WorkshopTask.allCases, id: \.self) { task in
            DecorationView(task: task, isLit: false)
        }
    }
    .padding(30)
    .background(Color.nightBackgroundTop)
}

#Preview("켜짐과 꺼짐 · 한 줄") {
    HStack(spacing: 44) {
        ForEach(WorkshopTask.allCases, id: \.self) { task in
            DecorationView(
                task: task,
                isLit: task == .wishReception || task == .wrapping
            )
            .frame(maxWidth: .infinity)
        }
    }
    .padding(30)
    .background(Color.nightBackgroundTop)
}

#Preview("나이트 · 다크") {
    HStack(spacing: 44) {
        DecorationView(task: .wishReception, isLit: true)
        DecorationView(task: .giftProduction, isLit: false)
    }
    .padding(30)
    .background(Color.nightBackgroundTop)
    .preferredColorScheme(.dark)
}

#Preview("큰 글자 · 썰매 적재") {
    DecorationView(task: .sleighLoading, isLit: true)
        .dynamicTypeSize(.accessibility3)
        .padding(30)
        .background(Color.nightBackgroundTop)
}
#endif
