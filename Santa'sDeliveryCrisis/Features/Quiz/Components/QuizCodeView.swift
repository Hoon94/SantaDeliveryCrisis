import SwiftUI

/// 문제 안의 코드와 확대창이 함께 사용하는 읽기 전용 Swift 코드 뷰.
struct QuizCodeView: View {
    let code: String
    /// 확대창에서는 양방향 스크롤과 작은 글자를 사용하고, 상단에 닫기 표시를 둔다.
    var isExpanded = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var highlightedSource: String?
    @State private var highlightedText = AttributedString()

    private var palette: QuizPalette { QuizPalette(colorScheme: colorScheme) }
    private var cornerRadius: CGFloat { isExpanded ? 10 : 16 }
    private var codeFont: Font { .system(isExpanded ? .footnote : .callout, design: .monospaced) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "swift")
                    .foregroundStyle(palette.accent)
                Text("Swift")
                    .foregroundStyle(palette.primaryText)
                Spacer(minLength: 8)
                Image(systemName: isExpanded ? "xmark" : "arrow.up.left.and.arrow.down.right")
                    .foregroundStyle(palette.secondaryText)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(palette.cardBackground)
            .accessibilityHidden(true)

            Rectangle()
                .fill(palette.border)
                .frame(height: 1)

            ScrollView(isExpanded ? [.horizontal, .vertical] : .horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    Text(lineNumbers)
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 12)
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(palette.border).frame(width: 1)
                        }
                        .accessibilityHidden(true)

                    Text(highlightedSource == code ? highlightedText : AttributedString(code))
                        .foregroundStyle(palette.primaryText)
                }
                .font(codeFont)
                .lineSpacing(5)
                .fixedSize(horizontal: true, vertical: true)
                .padding(14)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.subtleBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(palette.border, lineWidth: 1)
        }
        .task(id: code) {
            // 확대 연출의 매 프레임마다 문법을 다시 분석하지 않는다.
            highlightedText = SwiftCodeHighlighting.text(code)
            highlightedSource = code
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Swift 코드")
        .accessibilityValue(code)
    }

    /// 빈 줄과 마지막 개행도 줄 번호에 포함한다.
    private var lineNumbers: String {
        let count = code.reduce(1) { count, character in
            character.isNewline ? count + 1 : count
        }
        return (1...count).map { String($0) }.joined(separator: "\n")
    }
}

#Preview("코드 에디터 · 라이트") {
    QuizCodeView(code: "func addOne(_ x: inout Int) {\n    x += 1\n}\nvar v = 5\naddOne(&v)\nprint(v)")
        .padding()
        .preferredColorScheme(.light)
}

#Preview("코드 에디터 · 다크") {
    QuizCodeView(code: "// 소원을 확인해요\nlet name = \"산타 🎅\"\nprint(name)")
        .padding()
        .preferredColorScheme(.dark)
}
