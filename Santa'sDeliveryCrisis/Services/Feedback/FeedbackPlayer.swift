import Foundation

/// 효과음과 진동을 함께 내는 실제 피드백 재생기.
/// 설정(`soundEnabled`, `hapticsEnabled`)은 재생할 때마다 읽으므로 설정 화면에서 바꾸면 바로 반영된다.
final class FeedbackPlayer: QuizFeedbackPlaying {
    private let settings: SettingsStore
    private let sound = SoundPlayer()
    private let haptics = HapticPlayer()

    /// - Parameter settings: 소리와 진동 켜짐 여부를 읽는 설정
    init(settings: SettingsStore) {
        self.settings = settings
    }

    func playCorrect() { play(.correct) }
    func playWrong() { play(.wrong) }
    func playTreeComplete() { play(.treeComplete) }

    func play(_ cue: FeedbackCue) {
        if settings.soundEnabled { sound.play(cue) }
        if settings.hapticsEnabled { haptics.play(cue) }
    }

    func stop(_ cue: FeedbackCue) {
        sound.stop(cue)
        haptics.stop(cue)
    }
}
