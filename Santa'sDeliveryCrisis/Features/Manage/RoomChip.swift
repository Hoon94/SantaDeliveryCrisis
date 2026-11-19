import SwiftUI

/// 시안의 칩. 필터 선택, 행의 [수정]/[삭제] 같은 작은 버튼에 쓴다.
struct RoomChip: View {
    /// 칩의 모양
    enum Style {
        /// 기본(선택되지 않음)
        case normal
        /// 선택됨
        case selected
        /// 삭제처럼 되돌리기 어려운 동작
        case destructive
    }

    let title: String
    var style: Style = .normal
    /// 누를 수 있는지. false이면 흐리게 보이고 반응하지 않는다.
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .lineLimit(1)
                .foregroundStyle(foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(background, in: Capsule())
                .overlay {
                    if style == .destructive {
                        Capsule().stroke(foreground, lineWidth: 1)
                    }
                }
                // 눈에 보이는 크기보다 넓게 눌리도록 터치 영역을 키운다.
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityAddTraits(style == .selected ? .isSelected : [])
    }

    private var foreground: Color {
        switch style {
        case .normal: .roomSub
        case .selected: .roomOnAccent
        case .destructive: .roomBad
        }
    }

    private var background: Color {
        switch style {
        case .normal: .roomSoft
        case .selected: .roomAccent
        case .destructive: .clear
        }
    }
}

#Preview {
    HStack {
        RoomChip(title: "전체", style: .selected) {}
        RoomChip(title: "포장") {}
        RoomChip(title: "삭제", style: .destructive) {}
        RoomChip(title: "삭제", style: .destructive, isEnabled: false) {}
    }
    .padding()
    .background(Color.roomBackground)
}
