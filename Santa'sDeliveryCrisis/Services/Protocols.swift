import SwiftUI

/// 카테고리 추천 (S2 팝업의 [추천] 배지)
protocol TaskRecommending {
    /// 답한 기록이 있는 카테고리 중 정답률이 가장 낮은 카테고리.
    /// 동률이면 작업 순서(소원 접수, 선물 생산, 포장, 썰매 적재)가 앞선 쪽, 기록이 없으면 nil
    func recommendedCategory(sessions: [QuizSession]) -> QuizCategory?
}

/// 세션용 문제 선택. 선택 출제는 category를 하나만 넘긴다.
protocol QuestionSelecting {
    /// 조건에 맞는 문제를 `count`개 고른다.
    /// - Parameters:
    ///   - category: nil이면 4개 작업 전체에서 고르는 오늘의 출제
    ///   - tags: 비어 있으면 전체 태그. 여러 개면 하나라도 가진 문제. 오늘의 출제는 비움
    ///   - history: 답(정오답, 시각)과 풀 당시 스냅샷(카테고리, 태그)을 함께 읽는 세션 기록
    func select(
        category: QuizCategory?,
        difficulty: Difficulty,
        tags: Set<String>,
        count: Int,
        questions: [Question],
        history: [QuizSession]
    ) -> [Question]

    /// 조건에 맞는 문제 수. 문제 수 활성화와 장식 켜짐 판단에 쓴다.
    /// 카테고리를 여러 개 고른 경우 호출하는 쪽이 카테고리별로 호출해 합산한다.
    func availableCount(category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, questions: [Question]) -> Int
}

/// 세션 생성·진행·종료. SwiftData 저장을 담당한다.
protocol SessionManaging {
    /// 세션을 시작한다. category가 nil이면 오늘의 출제다.
    func startSession(category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, count: Int) throws -> QuizSession

    /// `questionIndex`번째 문제(0부터)에 답을 저장한다. 문제는 순서대로만 제출할 수 있다.
    /// 이미 답이 있는 문제에 다시 호출하면 처음 저장된 답을 돌려주고 새로 저장하지 않는다.
    /// 아직 답하지 않은 앞선 문제가 있는 순서로 호출하면 오류를 던진다.
    /// 답 저장과 `currentIndex` 갱신은 한 번의 저장으로 처리한다.
    func submit(answerIndex: Int, forQuestionAt questionIndex: Int, in session: QuizSession) throws -> SessionAnswer

    /// 이미 `completed`인 세션에 다시 호출하면 저장된 결과를 돌려주고 장식을 다시 지급하지 않는다.
    /// 세션 완료, 장식 지급, 트리 갱신은 한 번의 저장으로 처리한다.
    /// 실패하면 전부 취소하고 세션은 `inProgress`로 남아 재시도할 수 있다.
    func finish(_ session: QuizSession) throws -> SessionResult

    /// 이어 풀 수 있는 진행 중 세션. 없으면 nil
    func resumableSession() -> QuizSession?

    /// 진행 중 세션을 포기 처리한다.
    func abandon(_ session: QuizSession) throws

    /// 소요 시간(`elapsedSeconds`)을 저장한다. 퀴즈 화면이 시간을 누적하고, 이 함수는 저장만 한다.
    /// - Parameters:
    ///   - seconds: 증가분이 아니라 **누적 총합**. 같은 값을 여러 번 호출해도 결과가 같다.
    ///   - session: 대상 세션
    /// - 호출 시점: 답을 제출한 직후, 앱이 백그라운드로 갈 때, `finish` 직전
    /// - `inProgress`가 아닌 세션(완료, 포기)은 값을 바꾸지 않고 오류 없이 무시한다.
    /// - 저장된 값보다 작은 값은 무시한다(순서가 뒤바뀐 호출로 시간이 줄어들지 않게).
    /// - 음수나 숫자가 아닌 값(NaN, 무한대)은 `SessionError.invalidElapsed`를 던진다.
    func updateElapsed(_ seconds: TimeInterval, in session: QuizSession) throws
}

extension SessionManaging {
    /// 기본 구현은 아무것도 하지 않는다. 소요 시간을 저장하지 않는 가짜 구현(미리보기용)이 컴파일되도록 둔 것이고,
    /// 실제 `SessionManager`는 이 함수를 직접 구현한다.
    func updateElapsed(_ seconds: TimeInterval, in session: QuizSession) throws {}
}

/// 세션 결과 요약
struct SessionResult {
    let correctCount: Int
    let totalCount: Int
    let accuracyPercent: Int
    let elapsed: TimeInterval
    /// 기준 미만이면 0, 아니면 1
    let earnedDecorations: Int
    /// 이번 세션으로 트리가 완성되었는가
    let treeCompleted: Bool
    let wrongAnswers: [SessionAnswer]
}

/// 장식 지급과 트리 완성 처리
protocol TreeManaging {
    /// 현재 꾸미는 트리. 없으면 새로 만든다.
    func currentTree() -> TreeRecord

    /// 장식을 지급한다. 12칸이 차면 완성 처리 후 빈 트리를 새로 시작한다. 보상이 항상 1개라 이월은 없다.
    /// 같은 ModelContext에서 값만 바꾸고, 저장(save)은 `SessionManaging.finish`가 한 번만 호출한다.
    func grant(decorations: Int) throws -> TreeGrantResult

    /// 완성된 트리 목록
    func completedTrees() -> [TreeRecord]
}

/// 장식 지급 결과
struct TreeGrantResult {
    /// 이번 지급으로 완성된 트리. 없으면 nil
    let completedTree: TreeRecord?
    /// 지급 후 현재 트리의 장식 수
    let currentDecorationCount: Int
}

/// 효과음과 햅틱
protocol FeedbackPlaying {
    func playCorrect()
    func playWrong()
    func playTreeComplete()
}

/// 사용자 미디어 파일 저장과 정리. 정리 로직을 한 곳에 두고 문제 관리와 세션이 같이 호출한다.
protocol MediaFileManaging {
    /// 선택한 이미지·영상을 앱 내부 폴더에 새 파일명으로 복사하고 그 파일명을 돌려준다. 기존 파일은 덮어쓰지 않는다.
    func store(from url: URL) throws -> String

    /// 어떤 `Question`, 진행 중 세션 스냅샷, 원본이 남은 문제의 끝난 세션 스냅샷도 참조하지 않는 파일을 삭제한다.
    func cleanUnreferencedFiles() throws
}

/// 애니메이션 문제 한 단계
struct TraceStep {
    /// 하이라이트할 코드 줄 (1부터)
    let line: Int
    /// 말풍선과 VoiceOver 설명
    let narration: String
    /// 이 단계 이후의 변수 값
    let variables: [String: String]
    /// 캐릭터와 배경의 동작
    let sceneAction: TraceSceneAction
}

/// 캐릭터와 배경의 동작. 작업 5(애니메이션 문제)가 값을 정의한다.
/// 작업 0에서는 다른 작업이 컴파일되도록 빈 자리(`.none`)만 둔다.
enum TraceSceneAction { case none }

/// animationID로 장면과 실행 순서를 찾는 저장소
protocol TraceSceneRegistry {
    /// 장면을 찾지 못하면 nil
    func scene(for animationID: String) -> (steps: [TraceStep], view: AnyView)?
}
