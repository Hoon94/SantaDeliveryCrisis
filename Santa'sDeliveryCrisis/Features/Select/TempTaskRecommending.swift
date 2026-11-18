/// 실제 추천 서비스가 연결되기 전 화면에서 사용하는 임시 계약.
// FIXME: [mock 교체] A의 TaskRecommending이 Protocols.swift에 병합되면 이 파일을 삭제하고 AppServices로 교체
protocol TaskRecommending {
    /// 세션 기록에 대한 추천 카테고리 또는 추천 없음을 반환한다.
    // FIXME: [mock 교체] A의 TaskRecommending이 Protocols.swift에 병합되면 이 파일을 삭제하고 AppServices로 교체
    func recommendedCategory(sessions: [QuizSession]) -> QuizCategory?
}

/// 정답률 계산 없이 주입한 결과만 돌려주는 임시 추천기.
// FIXME: [mock 교체] A의 TaskRecommending이 Protocols.swift에 병합되면 이 파일을 삭제하고 AppServices로 교체
struct TempTaskRecommender: TaskRecommending {
    /// 미리 정한 추천 결과. 기본값은 추천 없음이다.
    // FIXME: [mock 교체] A의 TaskRecommending이 Protocols.swift에 병합되면 이 파일을 삭제하고 AppServices로 교체
    let category: QuizCategory?

    /// 프리뷰 등 호출부에서 추천 결과를 지정한다.
    // FIXME: [mock 교체] A의 TaskRecommending이 Protocols.swift에 병합되면 이 파일을 삭제하고 AppServices로 교체
    init(category: QuizCategory? = nil) {
        self.category = category
    }

    /// 실제 기록을 분석하지 않고 지정한 카테고리 또는 nil을 반환한다.
    // FIXME: [mock 교체] A의 TaskRecommending이 Protocols.swift에 병합되면 이 파일을 삭제하고 AppServices로 교체
    func recommendedCategory(sessions: [QuizSession]) -> QuizCategory? {
        category
    }
}
