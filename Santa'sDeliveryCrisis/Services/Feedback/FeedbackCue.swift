import Foundation

/// 퀴즈 화면의 인터랙션과 연출에서 효과음과 햅틱을 함께 내는 신호.
/// 소리는 `SoundSynth`가 코드로 합성하고, 진동은 `HapticPlayer`가 같은 이름의 패턴으로 만든다.
nonisolated enum FeedbackCue: String, CaseIterable, Sendable {
    /// 보기 선택
    case select
    /// [확인] 누름
    case confirm
    /// 힌트 열기
    case hint
    /// 일반 버튼
    case button
    /// 다음 문제로 넘어가기
    case next
    /// 정답
    case correct
    /// 오답
    case wrong
    /// 결과 팝업 등장
    case popup
    /// 장식 연출의 빛 모으기. 위로 올라가는 소리가 길게 이어진다.
    case chargeUp
    /// 번쩍이는 순간의 충격
    case impact
    /// 장식 조각이 터지는 소리(퍼, 펑)
    case burst
    /// 장식 획득 팡파르
    case reveal
    /// 트리 완성 팡파르
    case treeComplete
    /// 결과 화면의 장식이 트리를 향해 날아오르는 소리. 바람을 가르며 올라가는 쉬익
    case launch
    /// 장식이 트리에 흡수되는 소리. 부드러운 쿵과 맑은 종소리
    case absorb

    /// 소리 길이(초). 합성하는 버퍼 길이와 같다.
    var duration: Double {
        switch self {
        case .select: 0.14
        case .confirm: 0.30
        case .hint: 0.70
        case .button: 0.12
        case .next: 0.32
        case .correct: 1.00
        case .wrong: 0.55
        case .popup: 0.90
        case .chargeUp: FeedbackCue.chargeUpDuration
        case .impact: 1.30
        case .burst: 1.70
        case .reveal: 2.60
        case .treeComplete: 3.60
        case .launch: 0.90
        case .absorb: 1.30
        }
    }

    /// 빛 모으기 소리와 진동이 이어지는 시간(초). 연출의 충전 단계 길이와 맞춘다.
    static let chargeUpDuration: Double = 2.4
}
