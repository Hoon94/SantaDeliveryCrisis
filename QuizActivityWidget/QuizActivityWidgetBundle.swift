import WidgetKit
import SwiftUI

/// 앱에 포함할 홈 화면 위젯 목록.
@main
struct QuizActivityWidgetBundle: WidgetBundle {
    /// 월간 퀴즈 기록 위젯을 등록한다.
    var body: some Widget {
        QuizActivityWidget()
    }
}
