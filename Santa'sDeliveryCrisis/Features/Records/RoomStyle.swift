import SwiftUI

// 기록·설정 화면이 공유하는 시안(작업실 팔레트) 컴포넌트.
// 색은 모두 Asset 카탈로그의 `Room*` 색 세트(라이트/다크)를 쓴다. 카드 스타일은 `Extensions/View+RoomCardBackground.swift`.

/// 주간·월간과 정답률 선택에 쓰는 세그먼트. 다크 모드에서는 같은 초록 계열로 선택을 구분한다.
struct RoomSegmentedControl<Value: Hashable>: View {
    /// 선택 가능한 값과 화면에 보일 글자
    let options: [(value: Value, title: String, accessibilityLabel: String)]
    @Binding var selection: Value
    @Environment(\.colorScheme) private var colorScheme

    private var selectedBackground: Color {
        colorScheme == .dark ? .roomSecondaryText : .roomCardBackground
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    Text(option.title)
                        .font(.footnote.bold())
                        .foregroundStyle(isSelected ? Color.roomPrimaryText : Color.roomSecondaryText)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(selectedBackground)
                                    .shadow(color: Color.roomPrimaryText.opacity(0.15), radius: 1.5, y: 1)
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
        .background(Color.roomSubtleBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("선택 표시 · 다크 모드") {
    @Previewable @State var period = RecordsPeriod.week
    @Previewable @State var threshold = 80

    VStack(spacing: 24) {
        RoomSegmentedControl(
            options: RecordsPeriod.allCases.map { ($0, $0.displayName, $0.displayName) },
            selection: $period
        )
        RoomSegmentedControl(
            options: stride(from: 50, through: 100, by: 10).map { ($0, "\($0)", "\($0)퍼센트") },
            selection: $threshold
        )
    }
    .padding()
    .background(Color.roomBackground)
    .preferredColorScheme(.dark)
}

/// 시안의 얇은 진행 막대(높이 6)
struct RoomProgressBar: View {
    /// 0...1
    let fraction: Double
    let fill: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.roomSubtleBackground)
                Capsule()
                    .fill(fill)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}
