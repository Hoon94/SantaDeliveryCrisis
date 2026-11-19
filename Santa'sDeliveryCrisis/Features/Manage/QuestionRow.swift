import SwiftUI

/// 문제 관리 목록의 한 행. 제목, "작업 · 난이도 · 내 문제/기본 🔒", [수정]/[삭제] 칩을 보여 준다.
/// 기본(시드) 문제와 애니메이션 문제는 [수정]/[삭제]가 흐리게 보이고 반응하지 않는다.
struct QuestionRow: View {
    let question: Question
    let onEdit: () -> Void
    let onDelete: () -> Void

    /// 사용자가 고치거나 지울 수 있는 문제인지
    var isEditable: Bool { !question.isSeed && question.kind == .standard }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                titleBlock
                Spacer(minLength: 8)
                chips
            }
            VStack(alignment: .leading, spacing: 4) {
                titleBlock
                chips
            }
        }
        .padding(.vertical, 2)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titleText)
                .font(.subheadline.bold())
                .lineLimit(2)
                .foregroundStyle(Color.roomPrimaryText)
            Text(subtitleText)
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)
        }
    }

    private var chips: some View {
        HStack(spacing: 4) {
            RoomChip(title: "수정", isEnabled: isEditable, action: onEdit)
                .accessibilityHint(isEditable ? "" : "기본 문제는 수정할 수 없어요")
            RoomChip(title: "삭제", style: .destructive, isEnabled: isEditable, action: onDelete)
                .accessibilityHint(isEditable ? "" : "기본 문제는 삭제할 수 없어요")
        }
    }

    private var titleText: String {
        question.kind == .animation ? "🎬 \(question.text)" : question.text
    }

    private var subtitleText: String {
        let owner = question.isSeed ? "기본 🔒" : "내 문제"
        return "\(question.category.categoryName) · \(question.difficulty.displayName) · \(owner)"
    }
}
