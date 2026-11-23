#if DEBUG
/// 시작 또는 포기 오류를 재현하고 나머지는 주입된 서비스에 위임하는 프리뷰용 관리자.
struct FailingPreviewSessionManager: SessionManaging {
    /// 프리뷰에서 오류를 발생시킬 서비스 호출.
    enum Failure {
        /// 새 세션 생성에 실패한다.
        case start
        /// 기존 세션 포기에 실패한다.
        case abandon
    }

    private enum PreviewError: Error { case simulated }
    private let base: any SessionManaging
    private let failure: Failure

    /// 프리뷰마다 독립된 관리자와 실패 지점을 받는다.
    /// - Parameters:
    ///   - base: 오류를 강제하지 않는 호출을 처리할 서비스.
    ///   - failure: 상태를 바꾸기 전에 오류를 던질 호출.
    init(base: any SessionManaging, failure: Failure) {
        self.base = base
        self.failure = failure
    }

    /// 지정한 경우 생성 전에 오류를 던져 새 세션을 만들지 않는다.
    func startSession(
        task: WorkshopTask, categories: Set<QuizCategory>, difficulty: Difficulty, tags: Set<String>, count: Int
    ) throws -> QuizSession {
        if failure == .start { throw PreviewError.simulated }
        return try base.startSession(task: task, categories: categories, difficulty: difficulty, tags: tags, count: count)
    }

    /// 답 제출은 주입된 서비스에 위임하며 오류를 그대로 전달한다.
    func submit(answerIndex: Int, forQuestionAt questionIndex: Int, in session: QuizSession) throws -> SessionAnswer {
        try base.submit(answerIndex: answerIndex, forQuestionAt: questionIndex, in: session)
    }

    /// 결과 확정은 주입된 서비스에 위임하며 오류를 그대로 전달한다.
    func finish(_ session: QuizSession) throws -> SessionResult {
        try base.finish(session)
    }

    /// 기존 세션 조회 동작은 그대로 유지한다.
    func resumableSession() -> QuizSession? {
        base.resumableSession()
    }

    /// 지정한 경우 상태 변경 전에 오류를 던져 기존 세션을 유지한다.
    func abandon(_ session: QuizSession) throws {
        if failure == .abandon { throw PreviewError.simulated }
        try base.abandon(session)
    }
}
#endif
