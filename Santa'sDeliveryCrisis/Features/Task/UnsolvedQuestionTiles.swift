import SwiftUI

/// 계산된 난이도별 미풀이 문제 수를 표시하는 영역.
struct UnsolvedQuestionTiles: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 문제와 기록에서 계산한 표시용 값.
    let stats: UnsolvedQuestionStats

    /// 세 난이도 타일 또는 문제가 없을 때의 안내.
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    heading
                    totalLabel
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    heading
                    Spacer(minLength: 8)
                    totalLabel
                }
            }

            if stats.total == 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("아직 등록된 문제가 없어요")
                        .font(.subheadline.weight(.semibold))
                    Text("문제가 추가되면 난이도별 진행도를 볼 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(Color.roomSecondaryText)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.roomCardBackground, in: RoundedRectangle(cornerRadius: 14))
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: Difficulty.allCases.count),
                    spacing: 8
                ) {
                    ForEach(stats.byDifficulty, id: \.difficulty) { entry in
                        tile(entry)
                    }
                }
            }
        }
        .foregroundStyle(Color.roomPrimaryText)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var heading: some View {
        Text("아직 안 푼 문제")
            .font(.subheadline.weight(.heavy))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var totalLabel: some View {
        Text("총 \(stats.unsolved)문제")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.roomSecondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func tile(_ entry: UnsolvedQuestionStats.Entry) -> some View {
        VStack(spacing: 4) {
            Text(entry.difficulty.displayName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(difficultyColor(entry.difficulty), in: Capsule())

            Text("\(entry.unsolved)")
                .font(.title2.weight(.heavy))
            Text("/ \(entry.total)문제")
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)

            GeometryReader { geometry in
                Capsule()
                    .fill(Color.roomSubtleBackground)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(difficultyColor(entry.difficulty))
                            .frame(width: geometry.size.width * entry.solvedFraction)
                    }
            }
            .frame(height: 5)
            .padding(.horizontal, 8)
            .padding(.top, 2)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(Color.roomCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.roomBorder))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(entry.difficulty.displayName), 안 푼 문제 \(entry.unsolved)개, 전체 \(entry.total)문제"
        )
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: .roomPositive
        case .normal: .roomWarning
        case .hard: .roomAccent
        }
    }
}

#Preview("문제 타일 · 일부 풀이") {
    UnsolvedQuestionTiles(stats: UnsolvedQuestionStats(byDifficulty: [
        .init(difficulty: .easy, unsolved: 8, total: 20),
        .init(difficulty: .normal, unsolved: 14, total: 20),
        .init(difficulty: .hard, unsolved: 18, total: 20)
    ]))
    .padding()
    .background(Color.roomBackground)
}

#Preview("문제 타일 · 비어 있음") {
    UnsolvedQuestionTiles(stats: .calculate(questions: [], history: []))
        .padding()
        .background(Color.roomBackground)
}
