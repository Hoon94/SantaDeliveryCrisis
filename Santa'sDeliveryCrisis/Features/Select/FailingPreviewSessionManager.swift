/// 시작 또는 포기 오류를 재현하고 나머지는 기존 mock에 위임하는 프리뷰용 관리자.
// FIXME: [mock 교체] 실제 SessionManaging 통합 후 프리뷰 오류 주입을 실제 서비스 오류 시나리오로 교체
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

    /// 프리뷰마다 독립된 기존 관리자와 실패 지점을 받는다.
    init(base: any SessionManaging = MockSessionManager(), failure: Failure = .start) {
        self.base = base
        self.failure = failure
    }

    /// 지정한 경우 생성 전에 오류를 던져 새 세션을 만들지 않는다.
    func startSession(
        category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, count: Int
    ) throws -> QuizSession {
        if failure == .start { throw PreviewError.simulated }
        return try base.startSession(category: category, difficulty: difficulty, tags: tags, count: count)
    }

    /// 답 제출 동작은 기존 mock을 사용한다.
    func submit(answerIndex: Int, forQuestionAt questionIndex: Int, in session: QuizSession) throws -> SessionAnswer {
        try base.submit(answerIndex: answerIndex, forQuestionAt: questionIndex, in: session)
    }

    /// 결과 확정 동작은 기존 mock을 사용한다.
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
