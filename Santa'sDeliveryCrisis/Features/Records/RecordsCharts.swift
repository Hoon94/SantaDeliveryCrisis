import Charts
import SwiftUI

/// 풀이 문제 수 막대 차트. 주간은 요일별, 월간은 날짜별이다.
/// 주간에는 막대 위에 문제 수를 함께 보여 준다(월간은 막대가 많아 생략).
struct SolvedCountChart: View {
    let days: [DailyRecord]
    let period: RecordsPeriod

    private static let koreanLocale = Locale(identifier: "ko_KR")

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("풀이 문제 수")
                .font(.subheadline.bold())
            Chart(days) { day in
                BarMark(
                    x: .value("날짜", day.date, unit: .day),
                    y: .value("문제 수", day.solvedCount)
                )
                .foregroundStyle(Color.roomAccent)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                .annotation(position: .top, spacing: 2) {
                    if period == .week {
                        Text("\(day.solvedCount)")
                            .font(.caption2)
                            .foregroundStyle(Color.roomSecondaryText)
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                switch period {
                case .week:
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(
                            format: .dateTime.weekday(.narrow).locale(Self.koreanLocale),
                            centered: true
                        )
                        .foregroundStyle(Color.roomSecondaryText)
                    }
                case .month:
                    AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                        AxisValueLabel(format: .dateTime.day().locale(Self.koreanLocale), centered: true)
                            .foregroundStyle(Color.roomSecondaryText)
                    }
                }
            }
            .frame(height: 140)
            .accessibilityLabel("풀이 문제 수 막대 차트")
            .accessibilityValue(accessibilityText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .roomCardBackground()
    }

    private var accessibilityText: String {
        let solved = days.filter { $0.solvedCount > 0 }
        guard !solved.isEmpty else { return "푼 문제가 없어요" }
        return solved
            .map { "\($0.date.formatted(.dateTime.month().day().locale(Self.koreanLocale))) \($0.solvedCount)문제" }
            .joined(separator: ", ")
    }
}

#Preview {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: Date())
    let days = (0..<7).map { offset in
        DailyRecord(
            date: calendar.date(byAdding: .day, value: offset, to: start) ?? start,
            solvedCount: [4, 7, 5, 12, 9, 3, 6][offset]
        )
    }
    SolvedCountChart(days: days, period: .week)
        .padding()
        .background(Color.roomBackground)
}
