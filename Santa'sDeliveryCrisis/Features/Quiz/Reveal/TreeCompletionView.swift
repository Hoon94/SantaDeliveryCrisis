import SwiftUI
import UIKit

/// 완성한 트리에서 산타 마을로 이어지는 D1 출발 연출. 장식 부착이 끝난 뒤 약 10초 동안 재생한다.
struct TreeCompletionView: View {
    let summary: QuizResultSummary
    let feedback: any QuizFeedbackPlaying
    let onClose: () -> Void
    /// 프리뷰에서 장면을 고정한다. 실제 실행에서는 시간을 자동으로 진행한다.
    var debugTime: TimeInterval?
    /// DEBUG 빌드에서 연출의 장식만 열두 개로 표시한다. 실제 저장 결과는 변경하지 않는다.
    var showsFullTreeForTesting = false
    /// 프리뷰에서 정지 완성 장면을 확인한다. 시스템의 동작 줄이기 설정도 항상 반영한다.
    var forceReduceMotion = false

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var elapsedBeforePause: TimeInterval = 0
    @State private var playbackStartedAt: Date?
    @State private var nextCueIndex = 0
    @State private var showsResult = false

    private static let speech = "호호호! 크리스마스 선물을 전하러 출발하자!"
    private static let caption = "크리스마스 선물 배달, 출발!"

    private var reduceMotion: Bool { systemReduceMotion || forceReduceMotion }

    /// 새로 받은 보상을 마지막 장식으로 표시한다. 완성 직후 새 트리의 기록은 읽지 않는다.
    private var stages: [QuizStage] {
        #if DEBUG
        if showsFullTreeForTesting {
            return QuizStage.all.filter { $0 != summary.stage } + [summary.stage]
        }
        #endif
        return summary.treeRewardStages.filter { $0 != summary.stage } + [summary.stage]
    }

    private var isFinished: Bool {
        showsResult || reduceMotion || (debugTime ?? 0) >= TreeCompletionFrame.duration
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: scenePhase != .active || isFinished || debugTime != nil)) { timeline in
                let time = isFinished ? TreeCompletionFrame.duration : debugTime ?? playedTime(at: timeline.date)
                let frame = TreeCompletionFrame(time: time, size: geometry.size, reduced: reduceMotion)
                ZStack {
                    Color.roomBackground
                    roomScene(frame)
                        .opacity(1 - frame.villageOpacity)
                    villageScene(frame)
                        .opacity(frame.villageOpacity)

                    if isFinished {
                        closeControls(size: geometry.size)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if time < TreeCompletionFrame.captionAt {
                        playbackControls
                    }
                }
            }
        }
        .background { Color.roomBackground.ignoresSafeArea() }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: showsResult)
        .task(id: scenePhase) { await playWhenActive() }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { finish() }
        }
        .onDisappear {
            pauseClock()
            stopFeedback()
        }
    }

    // MARK: - 트리가 완성되는 작업실

    private func roomScene(_ frame: TreeCompletionFrame) -> some View {
        let side = frame.roomSide
        let pose = frame.time >= 2 ? (Int((frame.time - 2) * 2) % 2 == 0 ? 1 : 2) : 0
        return ZStack(alignment: .topLeading) {
            Image("PixelWorkshopRoom")
                .resizable()
                .interpolation(.none)
                .frame(width: side, height: side)

            ornaments(frame)

            Circle()
                .fill(RadialGradient(colors: [.glowGold.opacity(0.8), .clear], center: .center, startRadius: 0, endRadius: side * 0.16))
                .frame(width: side * 0.32, height: side * 0.32)
                .opacity(frame.starLight)
                .position(frame.star)
                .blendMode(.plusLighter)

            Image(systemName: "sparkle")
                .font(.system(size: side * 0.13))
                .foregroundStyle(Color.glowCore)
                .opacity(frame.starLight * 0.85)
                .position(frame.star)

            Image("PixelWorkshopArtisanSanta")
                .resizable()
                .interpolation(.none)
                .frame(width: side * 0.36 * 4, height: side * 0.48)
                .offset(x: -CGFloat(pose) * side * 0.36)
                .frame(width: side * 0.36, height: side * 0.48, alignment: .leading)
                .clipped()
                .offset(y: side * 0.43)

            SpeechBubble(text: Self.speech, tint: .glowGold)
                .frame(width: side * 0.62)
                .position(x: side * 0.35, y: side * 0.31)
                .opacity(frame.speechOpacity)
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .position(x: frame.roomOrigin.x + side / 2, y: frame.roomOrigin.y + side / 2)
        .accessibilityHidden(true)
    }

    /// 이미 부착된 장식에서 모인 빛이 꼭대기 별로 향한다.
    private func ornaments(_ frame: TreeCompletionFrame) -> some View {
        Canvas { context, _ in
            let side = frame.roomSide
            let radius = side * 7 / TreeSlots.designSize.width
            for (index, stage) in stages.enumerated() where TreeSlots.positions.indices.contains(index) {
                let slot = TreeSlots.positions[index]
                let destination = CGPoint(x: (slot.x + 0.11) * side, y: (slot.y * 0.9 - 0.045) * side)
                let center = destination
                let energy = RevealMath.smooth((frame.time - 0.85 - Double(11 - index) * 0.055) / 0.28)
                let circle = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                var ornament = context
                ornament.addFilter(.shadow(color: stage.task.themeColor.opacity(energy * 0.7), radius: radius * energy))
                ornament.fill(circle, with: .color(stage.task.themeColor))
                ornament.stroke(circle, with: .color(.glowCore), lineWidth: 1)

                let gather = RevealMath.smooth((frame.time - 1 - Double(index) * 0.025) / 0.85)
                if gather > 0 && gather < 1 {
                    let point = CGPoint(
                        x: destination.x + (frame.star.x - destination.x) * gather,
                        y: destination.y + (frame.star.y - destination.y) * gather
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)),
                        with: .color(.glowGold.opacity(1 - gather * 0.5))
                    )
                }
            }
        }
        .frame(width: frame.roomSide, height: frame.roomSide)
    }

    // MARK: - 마을과 썰매

    private func villageScene(_ frame: TreeCompletionFrame) -> some View {
        let width = max(frame.size.width, frame.size.height * 2)
        let pan = frame.reduced ? 0.5 : RevealMath.smooth((frame.time - TreeCompletionFrame.villageAt) / 5.4)
        return ZStack(alignment: .topLeading) {
            // 배경의 큰 너비가 썰매 좌표계까지 넓히지 않도록 표시 영역 안에 가둔다.
            Color.clear
                .frame(width: frame.size.width, height: frame.size.height)
                .overlay(alignment: .topLeading) {
                    Image("SantaVillageMap")
                        .resizable()
                        .interpolation(.none)
                        .frame(width: width, height: frame.size.height)
                        .offset(x: -(width - frame.size.width) * pan)
                }
                .clipped()
                .accessibilityHidden(true)

            if frame.sleighOpacity > 0 {
                flightTrail(frame)
                Image("TreeCompletionSleigh")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: frame.size.width * (frame.reduced ? 0.64 : 0.59))
                    .rotationEffect(.degrees(frame.reduced ? 0 : -3))
                    .shadow(color: Color.glowGold.opacity(0.35), radius: 6)
                    .position(frame.sleighCenter)
                    .opacity(frame.sleighOpacity)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 6) {
                Text(Self.caption)
                    .font(.title3.weight(.heavy))
                Text("열두 개의 장식으로 트리를 완성했어요")
                    .font(.subheadline)
            }
            .foregroundStyle(Color.roomPrimaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .background(Color.roomCardBackground.opacity(0.96), in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(width: frame.size.width, alignment: .top)
            .opacity(frame.captionOpacity)
            .accessibilityHidden(frame.captionOpacity < 0.5)
        }
        .frame(width: frame.size.width, height: frame.size.height)
        .clipped()
    }

    /// 비행 궤적 뒤에 별빛을 남긴다. 동작 줄이기에서는 그리지 않는다.
    private func flightTrail(_ frame: TreeCompletionFrame) -> some View {
        Canvas { context, _ in
            guard !frame.reduced else { return }
            for index in 1...24 {
                let progress = frame.flightProgress - Double(index) * 0.012
                guard progress >= 0 else { continue }
                let point = frame.flightPoint(progress)
                let next = frame.flightPoint(min(progress + 0.012, 1))
                let offset = CGSize(width: frame.size.width * 0.59 * 0.39, height: frame.size.width * 0.59 * 0.09)
                var path = Path()
                path.move(to: CGPoint(x: point.x - offset.width, y: point.y + offset.height))
                path.addLine(to: CGPoint(x: next.x - offset.width, y: next.y + offset.height))
                let strength = 1 - Double(index) / 25
                context.stroke(path, with: .color(.glowGold.opacity(strength * 0.75)), lineWidth: max(1, 4 * strength))
            }
        }
        .frame(width: frame.size.width, height: frame.size.height)
        .accessibilityHidden(true)
    }

    // MARK: - 조작과 결과

    private var playbackControls: some View {
        VStack {
            HStack {
                Text("트리가 완성됐어요!")
                    .font(.headline)
                Spacer(minLength: 8)
                Button("건너뛰기") {
                    feedback.play(.button)
                    finish()
                }
                .buttonStyle(.bordered)
                .accessibilityHint("완성 연출의 마지막 장면을 표시해요")
            }
            .foregroundStyle(Color.roomPrimaryText)
            .padding(12)
            .background(Color.roomCardBackground.opacity(0.96), in: RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func closeControls(size: CGSize) -> some View {
        VStack {
            Spacer()
            Button {
                feedback.play(.button)
                onClose()
            } label: {
                Text("작업실로 돌아가기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(16)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.roomOnAccentText)
            .background(Color.roomAccent, in: RoundedRectangle(cornerRadius: 16))
            .padding(16)
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - 재생 시간

    private func playedTime(at date: Date) -> TimeInterval {
        let running = playbackStartedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0
        return min(elapsedBeforePause + running, TreeCompletionFrame.duration)
    }

    private func pauseClock() {
        guard playbackStartedAt != nil else { return }
        elapsedBeforePause = playedTime(at: Date())
        playbackStartedAt = nil
    }

    private func finish() {
        pauseClock()
        stopFeedback()
        elapsedBeforePause = TreeCompletionFrame.duration
        showsResult = true
    }

    private func wait(until time: TimeInterval) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(max(0, time - playedTime(at: Date()))))
        } catch {
            return false
        }
        return !Task.isCancelled && scenePhase == .active && !showsResult && !reduceMotion
    }

    /// 앱이 활성일 때만 진행하며, 일시 정지 후에는 아직 재생하지 않은 신호부터 이어 간다.
    private func playWhenActive() async {
        guard scenePhase == .active else {
            pauseClock()
            stopFeedback()
            return
        }
        guard debugTime == nil, !showsResult else { return }
        if reduceMotion {
            finish()
            feedback.play(.treeComplete)
            return
        }
        playbackStartedAt = Date()
        let cues: [(time: TimeInterval, cue: FeedbackCue)] = [(1.9, .treeComplete), (4.4, .launch)]
        while nextCueIndex < cues.count {
            let event = cues[nextCueIndex]
            guard await wait(until: event.time) else { return }
            nextCueIndex += 1
            feedback.play(event.cue)
            if event.cue == .treeComplete {
                UIAccessibility.post(notification: .announcement, argument: Self.speech)
            }
        }
        guard await wait(until: TreeCompletionFrame.duration) else { return }
        finish()
        feedback.play(.popup)
        UIAccessibility.post(notification: .announcement, argument: Self.caption)
    }

    private func stopFeedback() {
        feedback.stop(.absorb)
        feedback.stop(.treeComplete)
        feedback.stop(.launch)
    }
}

#if DEBUG
#Preview("트리 완성 D1 · 출발 인사 · 라이트") {
    TreeCompletionView(summary: .previewTreeComplete, feedback: SilentFeedbackPlayer(), onClose: {}, debugTime: 2.6)
        .preferredColorScheme(.light)
}

#Preview("트리 완성 D1 · 썰매 비행 · 다크") {
    TreeCompletionView(summary: .previewTreeComplete, feedback: SilentFeedbackPlayer(), onClose: {}, debugTime: 6.4)
        .preferredColorScheme(.dark)
}

#Preview("트리 완성 D1 · 전체 재생") {
    TreeCompletionView(summary: .previewTreeComplete, feedback: SilentFeedbackPlayer(), onClose: {})
}

#Preview("트리 완성 D1 · 신규 보상 한 개로 테스트") {
    TreeCompletionView(
        summary: .previewSuccess, feedback: SilentFeedbackPlayer(), onClose: {},
        showsFullTreeForTesting: true
    )
}

#Preview("트리 완성 D1 · 배달 출발 문구") {
    TreeCompletionView(summary: .previewTreeComplete, feedback: SilentFeedbackPlayer(), onClose: {}, debugTime: 9.4)
        .preferredColorScheme(.dark)
}

#Preview("트리 완성 D1 · 동작 줄이기 · 라이트") {
    TreeCompletionView(summary: .previewTreeComplete, feedback: SilentFeedbackPlayer(), onClose: {}, forceReduceMotion: true)
        .preferredColorScheme(.light)
}

#Preview("트리 완성 D1 · 동작 줄이기 · 다크") {
    TreeCompletionView(summary: .previewTreeComplete, feedback: SilentFeedbackPlayer(), onClose: {}, forceReduceMotion: true)
        .preferredColorScheme(.dark)
}

#Preview("트리 완성 D1 · 결과 · 큰 글자") {
    TreeCompletionView(summary: .previewTreeComplete, feedback: SilentFeedbackPlayer(), onClose: {}, debugTime: 10)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
#endif
