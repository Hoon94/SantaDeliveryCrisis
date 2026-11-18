import SwiftUI

// 기록·설정 화면이 공유하는 시안(작업실 팔레트) 컴포넌트.
// 색은 모두 Asset 카탈로그의 `Room*` 색 세트(라이트/다크)를 쓴다. 카드 스타일은 `Extensions/View+RoomCard.swift`.

/// 시안의 세그먼트 컨트롤. 배경은 soft, 선택된 칸은 카드 색으로 떠 보인다.
struct RoomSegmentedControl<Value: Hashable>: View {
    /// 선택 가능한 값과 화면에 보일 글자
    let options: [(value: Value, title: String, accessibilityLabel: String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    Text(option.title)
                        .font(.footnote.bold())
                        .foregroundStyle(isSelected ? Color.roomText : Color.roomSub)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(Color.roomCard)
                                    .shadow(color: Color.roomText.opacity(0.15), radius: 1.5, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.accessibilityLabel)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Color.roomSoft, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// 시안의 얇은 진행 막대(높이 6)
struct RoomProgressBar: View {
    /// 0...1
    let fraction: Double
    let fill: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.roomSoft)
                Capsule()
                    .fill(fill)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}
