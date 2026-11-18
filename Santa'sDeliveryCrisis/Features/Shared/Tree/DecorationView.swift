import SwiftUI

/// 출제 화면에서 작업 이름과 선택 가능 상태를 보여 주는 정적 장식.
/// 글로우는 뷰 영역 밖으로 번지므로, 부모가 이 뷰를 `clipped()` 등으로 자르거나 `ScrollView`로 감쌀 때는 글로우가 잘릴 수 있다(스크롤 영역에서는 `scrollClipDisabled()`를 쓴다).
// FIXME: [자산 교체] 임시 도형으로 그린 구슬을 실제 장식 이미지로 교체
// FIXME: [가정 8] 시안 v3의 통과 점 3개, 체크 배지, 작업실 문 열림은 1차에서 제외. 팀이 확정하면 여기에 추가
struct DecorationView: View {
    /// 장식이 나타내는 작업.
    let category: QuizCategory
    /// 켜짐(선택됨, 눌러서 시작 가능) 여부. false면 흐리게 표시.
    let isLit: Bool

    /// 부모 공간에 맞춰 원본 비율을 유지하는 장식.
    var body: some View {
        GeometryReader { geometry in
            let scale = min(
                geometry.size.width / 84,
                geometry.size.height / 94
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
                    .fill(category.themeColor)
                    .frame(width: 84 * scale, height: 84 * scale)
                    .shadow(color: category.themeColor, radius: (isLit ? 22 : 9) * scale)
                    .position(center)

                Ellipse()
                    .fill(Color.treeHighlight.opacity(0.45))
                    .frame(width: 24 * scale, height: 14 * scale)
                    .position(x: center.x - 15 * scale, y: center.y - 24 * scale)

                Text(category.taskName)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color.treeHighlight)
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
        .aspectRatio(84.0 / 94.0, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.taskName), \(isLit ? "켜짐" : "꺼짐")")
    }
}

#Preview("네 작업 · 켜짐") {
    VStack(spacing: 44) {
        ForEach(QuizCategory.allCases, id: \.self) { category in
            DecorationView(category: category, isLit: true)
        }
    }
    .padding(30)
    .background(Color.nightBackgroundTop)
}

#Preview("네 작업 · 꺼짐") {
    VStack(spacing: 44) {
        ForEach(QuizCategory.allCases, id: \.self) { category in
            DecorationView(category: category, isLit: false)
        }
    }
    .padding(30)
    .background(Color.nightBackgroundTop)
}

#Preview("켜짐과 꺼짐 · 한 줄") {
    HStack(spacing: 44) {
        ForEach(QuizCategory.allCases, id: \.self) { category in
            DecorationView(
                category: category,
                isLit: category == .aiUsage || category == .hig
            )
            .frame(maxWidth: .infinity)
        }
    }
    .padding(30)
    .background(Color.nightBackgroundTop)
}

#Preview("나이트 · 다크") {
    HStack(spacing: 44) {
        DecorationView(category: .aiUsage, isLit: true)
        DecorationView(category: .swiftSyntax, isLit: false)
    }
    .padding(30)
    .background(Color.nightBackgroundTop)
    .preferredColorScheme(.dark)
}

#Preview("큰 글자 · 썰매 적재") {
    DecorationView(category: .swiftUIPractice, isLit: true)
        .dynamicTypeSize(.accessibility3)
        .padding(30)
        .background(Color.nightBackgroundTop)
}
