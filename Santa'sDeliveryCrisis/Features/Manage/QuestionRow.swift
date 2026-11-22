import SwiftUI

/// 문제 관리 목록의 한 행. 제목과 "카테고리 · 난이도 · 내 문제/기본"을 보여 준다.
/// 행을 누르면 상세 화면이 열리고, 수정·삭제 스와이프 동작은 목록에서 제공한다.
/// 기본(시드) 문제와 애니메이션 문제는 고치거나 지울 수 없어서 자물쇠를 보여 준다.
struct QuestionRow: View {
    let question: Question
    /// 행을 눌렀을 때 상세 화면을 여는 동작
    let onOpen: () -> Void

    /// 사용자가 고치거나 지울 수 있는 문제인지
    var isEditable: Bool { !question.isSeed && question.kind == .standard }

    var body: some View {
        titleBlock
            .padding(.vertical, 2)
    }

    /// 제목과 부제목. 누르면 상세 화면이 열린다(기본 문제와 내 문제 모두).
    private var titleBlock: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color.roomPrimaryText)
                subtitleLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("문제 상세 화면을 엽니다")
    }

    /// "카테고리 · 난이도 · 내 문제/기본" 한 줄. 기본(시드)·애니메이션 문제는 글자 바로 옆에 자물쇠를 둔다.
    private var subtitleLine: some View {
        HStack(spacing: 6) {
            Text(subtitleText)
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)
            if !isEditable {
                Image(systemName: "lock.fill")
                    .font(.callout)
                    .foregroundStyle(Color.roomSecondaryText)
                    .accessibilityLabel("수정할 수 없는 기본 문제")
            }
        }
    }

    private var titleText: String {
        question.kind == .animation ? "🎬 \(question.text)" : question.text
    }

    private var subtitleText: String {
        let owner = question.isSeed ? "기본" : "내 문제"
        return "\(question.category.categoryName) · \(question.difficulty.displayName) · \(owner)"
    }
}
