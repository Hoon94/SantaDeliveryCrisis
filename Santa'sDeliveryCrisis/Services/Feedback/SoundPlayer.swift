import AVFoundation

/// `SoundSynth`가 만든 소리를 `AVAudioEngine`으로 재생한다.
///
/// - 소리마다 재생 노드를 새로 만들어 붙이고 끝나면 떼므로, 여러 소리가 겹쳐도 서로 끊지 않는다.
/// - 조작음은 그대로, 연출음은 잔향(리버브)을 거쳐 내보낸다.
/// - 오디오 세션은 `.ambient`라서 무음 스위치를 따르고 다른 앱의 음악을 끊지 않는다.
final class SoundPlayer {
    private let engine = AVAudioEngine()
    private let reverb = AVAudioUnitReverb()
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.sampleRate, channels: 1)
    private var buffers: [FeedbackCue: AVAudioPCMBuffer] = [:]
    private var isPrepared = false
    private var isRendering = false
    /// 중간에 멈출 수 있어야 하는 소리의 노드
    private var stoppable: [FeedbackCue: AVAudioPlayerNode] = [:]
    /// 동시에 재생할 수 있는 최대 개수. 넘으면 새 소리는 무시한다.
    private var liveNodes = 0
    private let maxLiveNodes = 14

    /// 잔향을 거치는 신호. 짧은 조작음은 깨끗하게 둔다.
    private static let wetCues: Set<FeedbackCue> = [
        .correct, .wrong, .popup, .chargeUp, .impact, .burst, .reveal, .treeComplete, .launch, .absorb
    ]

    init() {}

    /// 오디오 세션과 엔진을 준비하고 모든 소리를 미리 합성한다. 여러 번 불러도 한 번만 한다.
    func prepare() {
        guard !isPrepared, format != nil else { return }
        isPrepared = true

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif

        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 26
        engine.attach(reverb)
        // 잔향 효과는 스테레오로 내보내므로 형식은 엔진이 정하게 둔다.
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = 1.0

        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.restartEngineIfNeeded() }
        }

        renderAllBuffers()
        startEngineIfNeeded()
    }

    /// 소리를 낸다. 준비가 안 됐으면 먼저 준비한다.
    func play(_ cue: FeedbackCue) {
        prepare()
        guard let format, let buffer = buffers[cue] else {
            // 합성이 아직 끝나지 않았다. 짧은 조작음 하나를 놓치는 것이 앱을 멈추는 것보다 낫다.
            return
        }
        guard liveNodes < maxLiveNodes else { return }
        startEngineIfNeeded()
        guard engine.isRunning else { return }

        let node = AVAudioPlayerNode()
        engine.attach(node)
        // 잔향 쪽 연결이 끊겨 있으면 소리가 안 나는 대신 앱이 죽을 수 있으므로, 그럴 때는 잔향 없이 그대로 보낸다.
        let reverbReady = !engine.outputConnectionPoints(for: reverb, outputBus: 0).isEmpty
        let destination: AVAudioNode = (Self.wetCues.contains(cue) && reverbReady) ? reverb : engine.mainMixerNode
        engine.connect(node, to: destination, format: format)
        guard !engine.outputConnectionPoints(for: node, outputBus: 0).isEmpty else {
            engine.detach(node)
            return
        }
        liveNodes += 1
        if cue == .chargeUp { stoppable[cue] = node }

        node.scheduleBuffer(buffer, at: nil, options: [], completionCallbackType: .dataPlayedBack) { [weak self, weak node] _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self, let node else { return }
                    self.release(node, cue: cue)
                }
            }
        }
        node.play()
    }

    /// 길게 이어지는 소리를 중간에 멈춘다.
    func stop(_ cue: FeedbackCue) {
        guard let node = stoppable[cue] else { return }
        // 갑자기 끊으면 딱 소리가 나므로 짧게 줄인 뒤 멈춘다.
        node.volume = 0
        release(node, cue: cue)
    }

    // MARK: - 내부

    private func release(_ node: AVAudioPlayerNode, cue: FeedbackCue) {
        guard node.engine != nil else { return }
        node.stop()
        engine.detach(node)
        liveNodes = max(liveNodes - 1, 0)
        if stoppable[cue] === node { stoppable[cue] = nil }
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            print("오디오 엔진 시작 실패: \(error.localizedDescription)")
        }
    }

    private func restartEngineIfNeeded() {
        guard !engine.isRunning else { return }
        startEngineIfNeeded()
    }

    /// 모든 신호의 소리를 백그라운드에서 합성하고, 끝나면 메인에서 버퍼로 바꿔 둔다.
    private func renderAllBuffers() {
        guard !isRendering, let format else { return }
        isRendering = true
        Task.detached(priority: .userInitiated) {
            var rendered: [(FeedbackCue, [Float])] = []
            for cue in FeedbackCue.allCases {
                rendered.append((cue, SoundSynth.samples(for: cue)))
            }
            await self.store(rendered, format: format)
        }
    }

    private func store(_ rendered: [(FeedbackCue, [Float])], format: AVAudioFormat) {
        for (cue, samples) in rendered {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
                  let channel = buffer.floatChannelData?[0] else { continue }
            samples.withUnsafeBufferPointer { source in
                if let base = source.baseAddress { channel.update(from: base, count: samples.count) }
            }
            buffer.frameLength = AVAudioFrameCount(samples.count)
            buffers[cue] = buffer
        }
    }
}
