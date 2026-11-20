import SwiftUI
import WidgetKit

/// 월간 요약과 달력. 데이터 조회와 저장은 하지 않고 전달받은 항목만 표시한다.
struct QuizActivityWidgetView: View {
    /// 타임라인에서 전달한 현재 표시 항목.
    let entry: QuizActivityEntry

    /// 미연결·오류 안내 또는 월간 학습 기록을 표시한다.
    var body: some View {
        switch entry.content {
        case .calendar(let activity):
            HStack(spacing: 16) {
                summary(activity)
                calendar(activity)
            }
        case .notConnected:
            notice(
                title: "월간 퀴즈 기록", message: "앱을 열어 기록을 연결해 주세요.",
                symbol: "calendar"
            )
        case .unavailable:
            notice(
                title: "기록을 불러오지 못했어요", message: "앱을 열어 다시 연결해 주세요.",
                symbol: "arrow.clockwise"
            )
        }
    }

    private func summary(_ activity: MonthlyQuizActivity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(String(activity.year))년 \(activity.month)월")
                .font(.headline)
            Spacer(minLength: 0)
            Image(systemName: activity.isTodayCompleted ? "checkmark.circle.fill" : "circle.dashed")
                .font(.title2)
                .foregroundStyle(activity.isTodayCompleted ? Color.green : Color.secondary)
                .widgetAccentable(activity.isTodayCompleted)
                .accessibilityHidden(true)
            Text(activity.isTodayCompleted ? "오늘 퀴즈 완료" : "오늘은 아직이에요")
                .font(.subheadline.bold())
                .fixedSize(horizontal: false, vertical: true)
            Text("이번 달 \(activity.completedDayCount)일 학습했어요")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func calendar(_ activity: MonthlyQuizActivity) -> some View {
        let cells = activity.calendarCells
        let rowCount = cells.count / 7
        return VStack(spacing: 3) {
            HStack(spacing: 3) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { column in
                        dayCell(cells[row * 7 + column], month: activity.month)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func dayCell(_ day: QuizActivityDay?, month: Int) -> some View {
        if let day {
            Text("\(day.dayNumber)")
                .font(.caption2.weight(day.isCompleted ? .bold : .regular))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(day.isFuture ? Color.secondary : Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(day.isCompleted ? Color.green.opacity(0.3) : Color.primary.opacity(0.04))
                }
                .overlay {
                    if day.isToday {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.primary, lineWidth: 1.5)
                    }
                }
                .widgetAccentable(day.isCompleted)
                .accessibilityLabel("\(month)월 \(day.dayNumber)일\(day.isToday ? ", 오늘" : ""), \(day.isCompleted ? "퀴즈 완료" : day.isFuture ? "예정" : "완료 기록 없음")")
        } else {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
        }
    }

    private func notice(title: String, message: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("월간 학습 · 라이트") {
    QuizActivityWidgetView(entry: .sample())
        .padding()
        .frame(width: 338, height: 158)
        .background(.background)
        .preferredColorScheme(.light)
}

#Preview("월간 학습 · 다크") {
    QuizActivityWidgetView(entry: .sample())
        .padding()
        .frame(width: 338, height: 158)
        .background(.background)
        .preferredColorScheme(.dark)
}
#endif
