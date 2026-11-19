import SwiftUI

/// 코드 전체를 크게 보여 주는 창. 테두리와 제목줄, 닫기 버튼이 없다.
/// 창 안이나 바깥의 어느 곳이든 한 번 누르면 닫힌다. 코드가 창보다 크면 위아래, 좌우로 밀어서 볼 수 있다.
struct CodePreviewPopup: View {
    let code: String
    /// 누르면 닫아야 할 때 부른다.
    let onClose: () -> Void

    /// 코드 글이 실제로 차지하는 크기. 짧은 코드는 창이 그 크기에 맞게 줄어든다.
    @State private var contentSize: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let maxWidth = min(proxy.size.width - 32, 760)
            let maxHeight = proxy.size.height * 0.82
            ZStack {
                Color.revealScrim.opacity(0.7)
                    .ignoresSafeArea()

                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.nightPrimaryText)
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(22)
                        .onGeometryChange(for: CGSize.self) { $0.size } action: { contentSize = $0 }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(
                    width: contentSize.width > 0 ? min(contentSize.width, maxWidth) : maxWidth,
                    height: contentSize.height > 0 ? min(contentSize.height, maxHeight) : maxHeight
                )
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.nightCardBackground)
                        .shadow(color: Color.inkShadow.opacity(0.35), radius: 28, y: 10)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .onTapGesture(perform: onClose)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("코드 전체 보기")
        .accessibilityValue(code)
        .accessibilityHint("누르면 닫혀요")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "닫기", onClose)
    }
}

#if DEBUG
#Preview("코드 크게 보기 · 짧은 코드") {
    ZStack {
        ThemeBackground(theme: .factory)
        CodePreviewPopup(code: "let apples = 3\nvar total = apples + 2\nprint(total)") {}
    }
}

#Preview("코드 크게 보기 · 긴 코드") {
    ZStack {
        ThemeBackground(theme: .factory)
        CodePreviewPopup(code: (1...40).map { "let value\($0) = \($0) * 2 // 아주 긴 한 줄짜리 설명이 오른쪽으로 이어집니다" }.joined(separator: "\n")) {}
    }
}
#endif
