import SwiftUI

/// 취약 카테고리 카드. 4개 카테고리를 모두 보여 주며 정답률이 낮은 순서로 "이름 / 막대 / 퍼센트" 한 줄씩 나온다.
/// 이 기간에 답한 문제가 없는 카테고리는 "-"로 표시하고 맨 아래에 둔다.
/// 정답률이 60% 미만이면 숫자가 빨강, 80% 이상이면 막대와 숫자가 초록이다.
/// 색에만 의존하지 않도록 정답률 숫자를 항상 함께 보여 주고, VoiceOver에는 상태를 말로 읽어 준다.
struct WeakCategoryList: View {
    /// 보여 줄 카테고리(정렬된 상태)
    let categories: [CategoryAccuracy]

    /// 이 값 미만이면 낮음(빨강)
    static let lowThreshold = 60
    /// 이 값 이상이면 높음(초록)
    static let highThreshold = 80

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("취약 카테고리")
                .font(.subheadline.bold())
            ForEach(categories) { item in
                row(for: item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .roomCardBackground()
    }

    private func row(for item: CategoryAccuracy) -> some View {
        let level = Level(percent: item.accuracyPercent)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                name(item)
                bar(item, level: level)
                value(item, level: level)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    name(item)
                    Spacer()
                    value(item, level: level)
                }
                bar(item, level: level)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.category.categoryName)
        .accessibilityValue(spokenValue(item, level: level))
    }

    private func name(_ item: CategoryAccuracy) -> some View {
        Text(item.category.categoryName)
            .font(.footnote)
            .lineLimit(1)
            .frame(minWidth: 84, alignment: .leading)
            .fixedSize()
    }

    private func bar(_ item: CategoryAccuracy, level: Level) -> some View {
        RoomProgressBar(
            fraction: Double(item.accuracyPercent ?? 0) / 100,
            fill: level.barColor
        )
        .frame(maxWidth: .infinity)
    }

    private func value(_ item: CategoryAccuracy, level: Level) -> some View {
        Text(item.accuracyPercent.map { "\($0)%" } ?? "-")
            .font(.footnote.bold())
            .foregroundStyle(level.textColor)
            .frame(minWidth: 40, alignment: .trailing)
            .fixedSize()
    }

    private func spokenValue(_ item: CategoryAccuracy, level: Level) -> String {
        guard let percent = item.accuracyPercent else { return "아직 푼 문제가 없어요" }
        return "정답률 \(percent)퍼센트, \(level.spokenText)"
    }

    /// 정답률 구간
    private enum Level {
        case none, low, middle, high

        init(percent: Int?) {
            guard let percent else {
                self = .none
                return
            }
            if percent < WeakCategoryList.lowThreshold {
                self = .low
            } else if percent >= WeakCategoryList.highThreshold {
                self = .high
            } else {
                self = .middle
            }
        }

        var barColor: Color { self == .high ? .roomPositive : .roomAccent }

        var textColor: Color {
            switch self {
            case .low: .roomNegative
            case .high: .roomPositive
            case .none: .roomSecondaryText
            case .middle: .roomPrimaryText
            }
        }

        var spokenText: String {
            switch self {
            case .none: "기록 없음"
            case .low: "낮음"
            case .middle: "보통"
            case .high: "높음"
            }
        }
    }
}

#Preview {
    WeakCategoryList(categories: [
        CategoryAccuracy(category: .swiftSyntax, accuracyPercent: 54, answeredCount: 13),
        CategoryAccuracy(category: .swiftUIPractice, accuracyPercent: 66, answeredCount: 9),
        CategoryAccuracy(category: .hig, accuracyPercent: 81, answeredCount: 16),
        CategoryAccuracy(category: .aiUsage, accuracyPercent: nil, answeredCount: 0),
    ])
    .padding()
    .background(Color.roomBackground)
}
