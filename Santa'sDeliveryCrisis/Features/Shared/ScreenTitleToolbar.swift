import SwiftUI

/// 기록 화면과 같은 위치와 글자 크기로 화면 제목을 표시하는 툴바.
struct ScreenTitleToolbar: ToolbarContent {
    let title: String
    let color: Color

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
        }
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) { titleLabel }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { titleLabel }
        }
    }

    private var titleLabel: some View {
        Text(title)
            .font(.title2.bold())
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }
}
