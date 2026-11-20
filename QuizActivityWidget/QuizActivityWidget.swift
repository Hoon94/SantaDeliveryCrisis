import SwiftUI
import WidgetKit

/// 표시 시각과 해당 시각의 달력 또는 안내 상태.
struct QuizActivityEntry: TimelineEntry {
    /// WidgetKit이 이 항목을 표시하기 시작할 시각.
    let date: Date
    /// 공유 기록으로 계산한 화면 상태.
    let content: Content

    /// 미연결·계산 오류를 정상적인 빈 기록과 구분한다.
    enum Content {
        case calendar(MonthlyQuizActivity)
        case notConnected
        case unavailable
    }

    /// 완료 시각을 해당 표시 날짜의 달력으로 바꾼다.
    init(date: Date, completedAt: [Date]?) {
        self.date = date
        if let completedAt {
            if let month = QuizActivityCalculator().month(completedAt: completedAt, now: date) {
                content = .calendar(month)
            } else {
                content = .unavailable
            }
        } else {
            content = .notConnected
        }
    }

    /// 공유 기록을 읽지 못한 경우의 안내 항목을 만든다.
    init(unavailableAt date: Date) {
        self.date = date
        content = .unavailable
    }

    /// 위젯 갤러리와 자리 표시자에서만 사용하는 샘플. 실제 저장소에는 쓰지 않는다.
    static func sample(at date: Date = Date()) -> QuizActivityEntry {
        let completedAt = [0, -2, -5, -8].compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: date)
        }
        return QuizActivityEntry(date: date, completedAt: completedAt)
    }
}

/// 공유 기록을 읽고 자정마다 오늘 표시와 월을 바꾸는 위젯 타임라인 제공자.
struct QuizActivityProvider: TimelineProvider {
    /// 기록을 읽기 전에 보여 줄 자리 표시자.
    func placeholder(in context: Context) -> QuizActivityEntry {
        .sample()
    }

    /// 갤러리는 샘플로, 실제 위젯 스냅샷은 공유 기록으로 구성한다.
    func getSnapshot(in context: Context, completion: @escaping (QuizActivityEntry) -> Void) {
        if context.isPreview {
            completion(.sample())
            return
        }
        completion(entries(from: Date()).first ?? QuizActivityEntry(unavailableAt: Date()))
    }

    /// 현재와 이후 7일의 자정을 제공한다. 실제 갱신 시점은 WidgetKit이 관리한다.
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuizActivityEntry>) -> Void) {
        completion(Timeline(entries: entries(from: Date()), policy: .atEnd))
    }

    private func entries(from now: Date) -> [QuizActivityEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let dates = [now] + (1...7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
        do {
            let completedAt = try QuizActivityStore().load()
            return dates.map { QuizActivityEntry(date: $0, completedAt: completedAt) }
        } catch {
            return dates.map { QuizActivityEntry(unavailableAt: $0) }
        }
    }
}

/// 이번 달의 학습 날짜와 오늘 완료 여부를 보여 주는 중간 크기 홈 화면 위젯.
struct QuizActivityWidget: Widget {
    /// 별도 사용자 설정 없이 공유 기록으로 달력을 구성한다.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: QuizActivityStore.widgetKind, provider: QuizActivityProvider()) { entry in
            QuizActivityWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("월간 퀴즈 기록")
        .description("오늘 퀴즈를 마쳤는지, 이번 달에 며칠 학습했는지 확인해요.")
        .supportedFamilies([.systemMedium])
    }
}

#if DEBUG
/// 달이 6주에 걸치는 2026년 8월의 고정 프리뷰 기록.
private func activityPreview(completedDays: [Int]) -> QuizActivityEntry {
    let calendar = Calendar(identifier: .gregorian)
    let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 20, hour: 12)) ?? Date()
    let completedAt = completedDays.compactMap {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: $0, hour: 10))
    }
    return QuizActivityEntry(date: now, completedAt: completedAt)
}

#Preview("연결 전", as: .systemMedium) {
    QuizActivityWidget()
} timeline: {
    QuizActivityEntry(date: .now, completedAt: nil)
}

#Preview("기록 없음", as: .systemMedium) {
    QuizActivityWidget()
} timeline: {
    activityPreview(completedDays: [])
}

#Preview("일부 완료 · 6주 달력", as: .systemMedium) {
    QuizActivityWidget()
} timeline: {
    activityPreview(completedDays: [1, 3, 5, 9, 12, 18])
}

#Preview("오늘 완료", as: .systemMedium) {
    QuizActivityWidget()
} timeline: {
    activityPreview(completedDays: [1, 3, 5, 9, 12, 18, 20])
}

#Preview("기록 읽기 실패", as: .systemMedium) {
    QuizActivityWidget()
} timeline: {
    QuizActivityEntry(unavailableAt: .now)
}
#endif
