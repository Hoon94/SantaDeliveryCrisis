import Foundation

/// 퀴즈 화면의 인터랙션과 연출이 쓰는 피드백 재생기.
/// 선택·버튼·정오답·완성 연출의 신호를 FeedbackCue로 구분한다.
protocol QuizFeedbackPlaying {
    /// 소리와 진동을 함께 낸다. 설정에서 꺼져 있으면 해당 부분은 내지 않는다.
    func play(_ cue: FeedbackCue)

    /// 길게 이어지는 신호(`chargeUp`)를 중간에 멈춘다. 이미 끝났거나 재생 중이 아니면 아무것도 하지 않는다.
    func stop(_ cue: FeedbackCue)

    /// 소리와 진동 엔진을 미리 준비한다. 처음 소리를 낼 때 생기는 멈춤을 피하려고 퀴즈 화면이 열릴 때 부른다.
    /// 여러 번 불러도 한 번만 준비한다. 구현이 따로 준비할 것이 없으면 아무것도 하지 않는다.
    func prepare()
}

extension QuizFeedbackPlaying {
    func prepare() {}
}

/// 아무것도 재생하지 않는 구현. 미리보기와 테스트에서 쓴다.
struct SilentFeedbackPlayer: QuizFeedbackPlaying {
    func play(_ cue: FeedbackCue) {}
    func stop(_ cue: FeedbackCue) {}
}
