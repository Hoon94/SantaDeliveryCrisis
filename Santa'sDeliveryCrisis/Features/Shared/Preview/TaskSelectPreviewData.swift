#if DEBUG
import SwiftData
import SwiftUI

/// 작업실·출제 프리뷰에서만 사용하는 샘플 데이터와 메모리 저장소.
@MainActor
enum TaskSelectPreviewData {
    /// 같은 메모리 저장소를 사용하는 프리뷰의 화면 환경.
    struct Environment {
        /// 앱의 영구 저장소와 분리된 모델 컨테이너.
        let container: ModelContainer
        /// 실제 선택기·세션·트리 로직과 프리뷰용 추천·피드백을 조립한 서비스.
        let services: AppServices
    }

    /// 정답이 첫 번째 보기인 문제를 만든다. 음수 개수는 0개로 보정한다.
    /// - Parameters:
    ///   - category: 모든 문제에 적용할 카테고리.
    ///   - difficulty: 모든 문제에 적용할 난이도.
    ///   - count: 생성할 문제 수.
    /// - Returns: 서로 다른 ID를 가진 샘플 문제 목록.
    static func questions(category: QuizCategory, difficulty: Difficulty, count: Int) -> [Question] {
        (0..<max(0, count)).map { index in
            Question(
                text: "미리보기 문제 \(index + 1)", choices: ["하나", "둘", "셋", "넷"],
                correctIndex: 0, explanation: "미리보기 해설",
                category: category, difficulty: difficulty
            )
        }
    }

    /// 문제 목록과 진행 위치가 일치하는 표시용 세션을 만든다. 서비스나 저장소는 변경하지 않는다.
    /// - Parameters:
    ///   - questions: 스냅샷으로 복사할 문제. 원본 문제와 풀이 기록의 ID를 일치시킨다.
    ///   - category: 단일 학습 카테고리. 혼합 출제는 nil이다.
    ///   - difficulty: 세션 표시에 사용할 난이도.
    ///   - task: 카테고리와 독립적인 보상 작업.
    ///   - answered: 답한 문제 수. 실제 문제 수 범위로 보정한다.
    ///   - status: 표시할 세션 상태.
    /// - Returns: 앞에서부터 답이 채워진 독립된 샘플 세션.
    static func session(
        questions: [Question], category: QuizCategory?, difficulty: Difficulty,
        task: WorkshopTask = .giftProduction,
        answered: Int = 0, status: SessionStatus = .inProgress
    ) -> QuizSession {
        let snapshots = questions.map { QuestionSnapshot($0) }
        let session = QuizSession(
            task: task,
            category: category, difficulty: difficulty, questionSnapshots: snapshots,
            passThresholdPercent: 80
        )
        session.answers = snapshots.prefix(max(0, answered)).map {
            SessionAnswer(questionID: $0.questionID, selectedIndex: 0, isCorrect: true)
        }
        session.currentIndex = session.answers.count
        session.status = status
        if status == .completed { session.rewardOutcome = .notEarned }
        session.finishedAt = status == .completed ? Date() : nil
        return session
    }

    /// 샘플 모델을 저장하고 실제 서비스가 같은 저장소를 읽도록 조립한다.
    /// - Parameters:
    ///   - questions: 출제 후보 및 통계에 사용할 문제.
    ///   - sessions: 진행 중 또는 풀이 기록으로 표시할 세션.
    ///   - trees: 현재 트리와 완성 기록.
    ///   - recommendedCategory: 프리뷰에 고정해 표시할 추천. nil이면 배지를 숨긴다.
    ///   - failure: 시작·포기 오류를 강제할 위치. nil이면 실제 서비스 동작을 사용한다.
    /// - Returns: 프리뷰마다 독립된 메모리 저장소와 서비스.
    /// - Throws: 메모리 저장소 생성 또는 샘플 모델 저장 오류.
    static func environment(
        questions: [Question] = [], sessions: [QuizSession] = [], trees: [TreeRecord] = [],
        recommendedCategory: QuizCategory? = nil,
        failure: FailingPreviewSessionManager.Failure? = nil
    ) throws -> Environment {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        questions.forEach { context.insert($0) }
        sessions.forEach { context.insert($0) }
        trees.forEach { context.insert($0) }
        try context.save()

        let source = AppServices.preview
        let selector = QuestionSelector()
        let treeManager = TreeManager(context: context)
        let sessionManager = SessionManager(
            context: context, selector: selector, trees: treeManager,
            settings: source.settings
        )
        let sessionService: any SessionManaging
        if let failure {
            sessionService = FailingPreviewSessionManager(base: sessionManager, failure: failure)
        } else {
            sessionService = sessionManager
        }
        let services = AppServices(
            settings: source.settings, selector: selector,
            recommender: MockTaskRecommender(category: recommendedCategory),
            sessions: sessionService, trees: treeManager, feedback: source.feedback,
            media: source.media, traceScenes: source.traceScenes
        )
        return Environment(container: container, services: services)
    }
}
#endif
