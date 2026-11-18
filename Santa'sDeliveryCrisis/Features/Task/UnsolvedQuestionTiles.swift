import SwiftUI

/// 계산된 난이도별 미풀이 문제 수를 표시하는 영역.
struct UnsolvedQuestionTiles: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 문제와 기록에서 계산한 표시용 값.
    let stats: UnsolvedQuestionStats

    /// 세 난이도 타일 또는 문제가 없을 때의 안내.
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

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

    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        return layout {
            heading
            if dynamicTypeSize.isAccessibilitySize == false {
                Spacer(minLength: 0)
            }
            totalLabel
        }
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

            ProgressView(value: entry.solvedFraction)
                .progressViewStyle(.linear)
                .tint(difficultyColor(entry.difficulty))
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

#if DEBUG
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
#endif
