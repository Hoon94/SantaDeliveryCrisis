import SwiftUI

/// 코드 전체를 크게 보여 주는 창. 테두리와 제목줄, 닫기 버튼이 없다.
///
/// - 모양: 맥 터미널 창처럼 어두운 배경에 밝은 글자, 작은 모서리 곡률(10pt). 색은 `TerminalBackground`, `TerminalText`에서 바꾼다.
/// - 크기: 화면 한가운데에, 화면 높이의 약 3분의 2. 글자는 코드 상자보다 작게 해서 한눈에 더 많이 보이게 한다.
/// - 열기: 누른 코드 상자에서 창이 커지며 펼쳐진다. 뒤 화면은 창과 같은 흐름으로 서서히 어두워진다.
/// - 닫기: 창 안이나 바깥을 한 번 누르면 반대로 접힌다.
///
/// 모든 움직임은 `progress` 하나(0 닫힘, 1 열림)에서 나온다. 창 위치와 크기, 모서리 곡률, 배경 어둡기, 글자 등장이
/// 같은 용수철을 타므로 서로 어긋나지 않는다. 모션 줄이기가 켜져 있으면 크기 변화 없이 페이드만 쓴다.
struct CodePreviewPopup: View {
    let code: String
    /// 열기 시작하는 자리(코드 상자)의 화면 좌표. 모르면 nil이고, 이때는 가운데에서 살짝 커지며 나타난다.
    let sourceFrame: CGRect?
    /// 닫는 움직임이 끝난 뒤 부른다. 부모는 이 창을 화면에서 치운다.
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0이면 닫힘, 1이면 열림. 용수철이 1을 살짝 넘겼다 돌아온다.
    @State private var progress: Double = 0
    @State private var isClosing = false

    private static let finalCornerRadius: CGFloat = 10
    private static let sourceCornerRadius: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            let screen = proxy.frame(in: .global)
            let target = targetSize(in: proxy.size)
            let finalRect = CGRect(
                x: (proxy.size.width - target.width) / 2,
                y: (proxy.size.height - target.height) / 2,
                width: target.width,
                height: target.height
            )
            let startRect = startRect(finalRect: finalRect, screen: screen)
            let rect = interpolated(from: startRect, to: finalRect)
            let radius = CGFloat(RevealMath.lerp(Double(Self.sourceCornerRadius), Double(Self.finalCornerRadius), min(max(progress, 0), 1)))
            // 창이 70%쯤 펼쳐진 뒤에 글자가 떠올라, 커지는 동안 글자가 일그러져 보이지 않는다.
            let textOpacity = RevealMath.smooth((progress - 0.3) / 0.45)

            ZStack {
                // 뒤 화면을 덮는 어둠. 창과 따로 화면 전체를 채우고, 같은 progress로 서서히 짙어진다.
                Color.revealScrim
                    .opacity(0.62 * min(max(progress, 0), 1))
                    .ignoresSafeArea()

                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Text(code)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(Color.terminalText)
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(20)
                        .frame(minWidth: finalRect.width, minHeight: finalRect.height, alignment: .topLeading)
                        .opacity(textOpacity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(width: finalRect.width, height: finalRect.height, alignment: .topLeading)
                .frame(width: rect.width, height: rect.height, alignment: .topLeading)
                .background(Color.terminalBackground)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .shadow(color: Color.inkShadow.opacity(0.5 * min(max(progress, 0), 1)), radius: 34, y: 14)
                .position(x: rect.midX, y: rect.midY)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .onTapGesture(perform: close)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(openAnimation) { progress = 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("코드 전체 보기")
        .accessibilityValue(code)
        .accessibilityHint("누르면 닫혀요")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "닫기", close)
    }

    // MARK: - 크기와 움직임

    /// 창의 최종 크기. 화면 높이의 약 3분의 2, 너비는 양옆을 조금 남긴다.
    private func targetSize(in screen: CGSize) -> CGSize {
        CGSize(
            width: min(screen.width * 0.9, 760),
            height: min(max(screen.height * 2 / 3, 220), screen.height - 80)
        )
    }

    /// 열리기 시작하는 모양. 코드 상자 자리(화면 좌표를 이 뷰 좌표로 바꾼 값)에서 시작한다.
    /// 자리를 모르거나 모션 줄이기가 켜져 있으면 최종 모양을 조금 줄인 크기에서 시작한다.
    private func startRect(finalRect: CGRect, screen: CGRect) -> CGRect {
        if reduceMotion { return finalRect }
        if let sourceFrame, sourceFrame.width > 20, sourceFrame.height > 10 {
            return sourceFrame.offsetBy(dx: -screen.minX, dy: -screen.minY)
        }
        let scale = 0.86
        let size = CGSize(width: finalRect.width * scale, height: finalRect.height * scale)
        return CGRect(x: finalRect.midX - size.width / 2, y: finalRect.midY - size.height / 2, width: size.width, height: size.height)
    }

    private func interpolated(from a: CGRect, to b: CGRect) -> CGRect {
        let t = progress
        return CGRect(
            x: RevealMath.lerp(a.minX, b.minX, t),
            y: RevealMath.lerp(a.minY, b.minY, t),
            width: max(RevealMath.lerp(a.width, b.width, t), 1),
            height: max(RevealMath.lerp(a.height, b.height, t), 1)
        )
    }

    private var openAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.52, dampingFraction: 0.86)
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        // 접힐 때는 튕기지 않게 부드럽게 줄이고, 어둠도 같이 걷힌다.
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.3), completionCriteria: .logicallyComplete) {
            progress = 0
        } completion: {
            onClose()
        }
    }
}

#if DEBUG
#Preview("코드 크게 보기 · 짧은 코드") {
    ZStack {
        ThemeBackground(theme: .factory)
        CodePreviewPopup(code: "let apples = 3\nvar total = apples + 2\nprint(total)", sourceFrame: CGRect(x: 16, y: 260, width: 360, height: 90)) {}
    }
}

#Preview("코드 크게 보기 · 긴 코드") {
    ZStack {
        ThemeBackground(theme: .factory)
        CodePreviewPopup(
            code: (1...40).map { "let value\($0) = \($0) * 2 // 아주 긴 한 줄짜리 설명이 오른쪽으로 이어집니다" }.joined(separator: "\n"),
            sourceFrame: nil
        ) {}
    }
}
#endif
