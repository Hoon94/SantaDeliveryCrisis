import Foundation

/// 효과음을 코드로 합성한다. 음원 파일이 없어도 저작권 걱정 없이 소리를 낼 수 있고, 같은 코드가 항상 같은 소리를 만든다.
///
/// 방식은 가산 합성(사인파를 더해 음색을 만듦)과 필터를 거친 노이즈다.
/// - 종소리: 정수배가 아닌 배음을 여러 개 겹치고 높은 배음일수록 빨리 사라지게 한다.
/// - 충전음: 높이가 지수로 올라가는 음에 떨림(비브라토, 트레몰로)의 속도를 점점 높인다.
/// - 충격음: 낮은 음이 빠르게 내려가는 쿵 소리, 필터로 깎은 노이즈, 짧은 딱 소리를 겹친다.
///
/// 결과는 모노 `Float` 샘플(-1...1)이다. 잔향은 재생할 때 오디오 엔진이 더한다.
nonisolated enum SoundSynth {
    /// 샘플링 주파수(Hz)
    static let sampleRate: Double = 44_100

    /// 신호에 맞는 소리를 합성한다.
    static func samples(for cue: FeedbackCue) -> [Float] {
        var out = [Float](repeating: 0, count: Int(cue.duration * sampleRate))
        switch cue {
        case .select: renderSelect(&out)
        case .confirm: renderConfirm(&out)
        case .hint: renderHint(&out)
        case .button: renderButton(&out)
        case .next: renderNext(&out)
        case .correct: renderCorrect(&out)
        case .wrong: renderWrong(&out)
        case .popup: renderPopup(&out)
        case .chargeUp: renderChargeUp(&out)
        case .impact: renderImpact(&out)
        case .burst: renderBurst(&out)
        case .reveal: renderReveal(&out)
        case .treeComplete: renderTreeComplete(&out)
        }
        finish(&out, gain: cue.targetPeak)
        return out
    }

    // MARK: - 신호별 소리

    /// 보기 선택: 나무 블록을 톡 두드리는 소리
    private static func renderSelect(_ out: inout [Float]) {
        addMallet(&out, freq: 520, start: 0, dur: 0.12, amp: 0.8, decay: 0.035, drop: 0.78)
        addNoise(&out, start: 0, dur: 0.012, amp: 0.25, lowCut: 2500, highCut: 6000, decay: 0.004, seed: 11)
    }

    /// [확인]: 올라가는 두 음
    private static func renderConfirm(_ out: inout [Float]) {
        addMallet(&out, freq: 587, start: 0.00, dur: 0.16, amp: 0.7, decay: 0.05, drop: 0.95)
        addMallet(&out, freq: 880, start: 0.07, dur: 0.22, amp: 0.8, decay: 0.07, drop: 0.97)
    }

    /// 힌트: 세 음이 올라가는 작은 종소리
    private static func renderHint(_ out: inout [Float]) {
        addBell(&out, freq: 880, start: 0.00, dur: 0.6, amp: 0.45, decay: 0.22)
        addBell(&out, freq: 1175, start: 0.08, dur: 0.6, amp: 0.45, decay: 0.22)
        addBell(&out, freq: 1568, start: 0.16, dur: 0.54, amp: 0.5, decay: 0.24)
    }

    /// 일반 버튼: 짧고 밝은 틱
    private static func renderButton(_ out: inout [Float]) {
        addMallet(&out, freq: 760, start: 0, dur: 0.1, amp: 0.7, decay: 0.03, drop: 0.85)
    }

    /// 다음 문제: 위로 스치는 바람 소리와 틱
    private static func renderNext(_ out: inout [Float]) {
        addSweepNoise(&out, start: 0, dur: 0.3, from: 500, to: 3200, amp: 0.5, q: 0.6, seed: 21)
        addMallet(&out, freq: 660, start: 0.2, dur: 0.1, amp: 0.4, decay: 0.03, drop: 0.9)
    }

    /// 정답: 위로 올라가는 세 음의 맑은 종소리
    private static func renderCorrect(_ out: inout [Float]) {
        addBell(&out, freq: 784, start: 0.00, dur: 0.9, amp: 0.55, decay: 0.28)
        addBell(&out, freq: 1047, start: 0.09, dur: 0.85, amp: 0.55, decay: 0.28)
        addBell(&out, freq: 1319, start: 0.18, dur: 0.8, amp: 0.6, decay: 0.32)
        addBell(&out, freq: 2093, start: 0.18, dur: 0.6, amp: 0.2, decay: 0.2)
    }

    /// 오답: 낮게 내려가는 둔탁한 소리. 날카롭지 않게 필터로 깎는다.
    private static func renderWrong(_ out: inout [Float]) {
        addTone(&out, start: 0, dur: 0.5, from: 247, to: 156, amp: 0.7, decay: 0.16, harmonics: [1, 0.5, 0.25])
        addTone(&out, start: 0.0, dur: 0.4, from: 124, to: 78, amp: 0.5, decay: 0.14, harmonics: [1])
        addNoise(&out, start: 0, dur: 0.05, amp: 0.25, lowCut: 200, highCut: 1500, decay: 0.02, seed: 31)
    }

    /// 결과 팝업: 유리 같은 맑은 소리
    private static func renderPopup(_ out: inout [Float]) {
        addSweepNoise(&out, start: 0, dur: 0.25, from: 800, to: 4000, amp: 0.25, q: 0.5, seed: 41)
        addBell(&out, freq: 1568, start: 0.12, dur: 0.75, amp: 0.45, decay: 0.3)
        addBell(&out, freq: 2349, start: 0.16, dur: 0.7, amp: 0.3, decay: 0.26)
    }

    /// 빛 모으기: 지이이잉. 높이가 지수로 오르고 떨림이 점점 빨라진다.
    private static func renderChargeUp(_ out: inout [Float]) {
        let n = out.count
        let dur = Double(n) / sampleRate
        var phaseA = 0.0, phaseB = 0.0, phaseSub = 0.0
        var lfoPhase = 0.0
        var noise = NoiseGen(seed: 51)
        var band = SVF()
        for i in 0..<n {
            let t = Double(i) / sampleRate
            let p = t / dur
            // 높이: 150Hz에서 시작해 1500Hz 근처까지 지수로 올라간다. 끝부분에서 더 가파르게.
            let freq = 150 * pow(10.0, pow(p, 1.5))
            // 떨림 속도: 3Hz에서 34Hz로 빨라진다.
            let lfoRate = 3 + 31 * p * p
            lfoPhase += 2 * .pi * lfoRate / sampleRate
            let lfo = sin(lfoPhase)
            let vibrato = 1 + lfo * (0.004 + 0.022 * p)
            phaseA += 2 * .pi * freq * vibrato / sampleRate
            phaseB += 2 * .pi * freq * 1.006 * vibrato / sampleRate   // 살짝 어긋난 두 번째 음으로 두께를 준다
            phaseSub += 2 * .pi * (48 + 52 * p) / sampleRate

            let tone = sin(phaseA) + 0.5 * sin(2 * phaseA) + 0.28 * sin(3 * phaseA)
            let tone2 = sin(phaseB) + 0.4 * sin(2 * phaseB)
            let tremolo = 1 - (0.12 + 0.28 * p) * (0.5 + 0.5 * lfo)
            var s = Float((tone * 0.5 + tone2 * 0.35) * tremolo)

            // 위로 갈수록 커지는 반짝이는 노이즈(고음역만 통과)
            let nz = noise.next()
            let hi = band.process(nz, f: 0.55 + 0.25 * Float(p), q: 0.9).high
            s += hi * Float(0.05 + 0.32 * p * p)

            // 바닥을 깔아 주는 낮은 울림
            s += Float(sin(phaseSub) * (0.08 + 0.16 * p))

            // 시작은 부드럽게, 점점 커지고, 끝나기 직전에 잠깐 줄여 번쩍임이 들어올 틈을 만든다.
            let attack = min(t / 0.06, 1)
            let swell = 0.22 + 0.78 * pow(p, 1.1)
            let tail = min((dur - t) / 0.03, 1)
            out[i] = s * Float(attack * swell * max(tail, 0))
        }
    }

    /// 번쩍임의 충격: 낮은 쿵, 노이즈 폭발, 딱 하는 소리, 높은 반짝임
    private static func renderImpact(_ out: inout [Float]) {
        addTone(&out, start: 0, dur: 0.9, from: 130, to: 38, amp: 1.0, decay: 0.3, harmonics: [1, 0.3])
        addSweepNoise(&out, start: 0, dur: 0.6, from: 3600, to: 200, amp: 0.9, q: 0.8, seed: 61, decay: 0.2)
        addNoise(&out, start: 0, dur: 0.02, amp: 0.9, lowCut: 3000, highCut: 9000, decay: 0.006, seed: 62)
        addBell(&out, freq: 2093, start: 0.01, dur: 1.2, amp: 0.28, decay: 0.45)
        addBell(&out, freq: 3136, start: 0.02, dur: 1.1, amp: 0.2, decay: 0.4)
    }

    /// 장식 조각이 터지는 소리: 퍼(작게), 펑(크게), 이어서 반짝이는 조각들
    private static func renderBurst(_ out: inout [Float]) {
        addPop(&out, start: 0.00, amp: 0.7, pitch: 1.0, seed: 71)
        addPop(&out, start: 0.17, amp: 1.0, pitch: 1.18, seed: 72)
        var rng = NoiseGen(seed: 73)
        let notes: [Double] = [2093, 2349, 2637, 3136, 3520, 4186]
        for k in 0..<16 {
            let start = 0.14 + Double(k) * 0.07 + Double((rng.next() + 1) * 0.03)
            let freq = notes[(k * 5 + Int((rng.next() + 1) * 3)) % notes.count]
            addBell(&out, freq: freq, start: start, dur: 0.5, amp: 0.12 + 0.05 * Float(rng.next()), decay: 0.14)
        }
    }

    /// 장식 획득: 밝은 종소리가 계단처럼 올라가고, 따뜻한 화음이 남는다.
    private static func renderReveal(_ out: inout [Float]) {
        let run: [Double] = [523, 659, 784, 1047, 1319]
        for (k, f) in run.enumerated() {
            addBell(&out, freq: f, start: Double(k) * 0.085, dur: 1.9, amp: 0.42, decay: 0.55)
        }
        addPad(&out, freqs: [262, 392, 659], start: 0.1, dur: 2.4, amp: 0.2)
        addBell(&out, freq: 2093, start: 0.45, dur: 1.6, amp: 0.3, decay: 0.5)
        var rng = NoiseGen(seed: 81)
        for k in 0..<10 {
            let start = 0.5 + Double(k) * 0.12 + Double((rng.next() + 1) * 0.04)
            addBell(&out, freq: 2400 + Double((rng.next() + 1) * 900), start: start, dur: 0.4, amp: 0.1, decay: 0.12)
        }
    }

    /// 트리 완성: 길게 올라가는 팡파르와 마지막 화음
    private static func renderTreeComplete(_ out: inout [Float]) {
        let run: [Double] = [392, 494, 587, 784, 988, 1175, 1568]
        for (k, f) in run.enumerated() {
            addBell(&out, freq: f, start: Double(k) * 0.1, dur: 1.4, amp: 0.4, decay: 0.45)
        }
        let chordStart = 0.85
        for f in [523.0, 659.0, 784.0, 1047.0, 1319.0, 1568.0] {
            addBell(&out, freq: f, start: chordStart, dur: 2.6, amp: 0.32, decay: 0.9)
        }
        addPad(&out, freqs: [262, 330, 392, 523], start: chordStart, dur: 2.7, amp: 0.26)
        var rng = NoiseGen(seed: 91)
        for k in 0..<24 {
            let start = 0.9 + Double(k) * 0.09 + Double((rng.next() + 1) * 0.04)
            addBell(&out, freq: 2200 + Double((rng.next() + 1) * 1400), start: start, dur: 0.45, amp: 0.1, decay: 0.13)
        }
    }

    // MARK: - 소리 재료

    /// 종소리. 정수배가 아닌 배음을 겹쳐 금속 느낌을 낸다.
    private static func addBell(_ out: inout [Float], freq: Double, start: Double, dur: Double, amp: Float, decay: Double) {
        let partials: [(ratio: Double, gain: Double, decayScale: Double)] = [
            (1.0, 1.0, 1.0), (2.0, 0.45, 0.7), (2.76, 0.33, 0.5), (5.40, 0.16, 0.3), (8.93, 0.07, 0.18)
        ]
        let first = Int(start * sampleRate)
        let count = Int(dur * sampleRate)
        for part in partials {
            let w = 2 * Double.pi * freq * part.ratio / sampleRate
            let g = part.gain * Double(amp)
            let d = decay * part.decayScale
            if freq * part.ratio > sampleRate * 0.45 { continue }
            for k in 0..<count {
                let idx = first + k
                if idx >= out.count { break }
                let t = Double(k) / sampleRate
                let env = exp(-t / d) * min(t / 0.002, 1)
                out[idx] += Float(sin(w * Double(k)) * g * env)
            }
        }
    }

    /// 나무 채로 친 듯한 짧은 소리. 높이가 살짝 내려간다.
    private static func addMallet(_ out: inout [Float], freq: Double, start: Double, dur: Double, amp: Float, decay: Double, drop: Double) {
        let first = Int(start * sampleRate)
        let count = Int(dur * sampleRate)
        var phase = 0.0
        for k in 0..<count {
            let idx = first + k
            if idx >= out.count { break }
            let t = Double(k) / sampleRate
            let f = freq * (drop + (1 - drop) * exp(-t / 0.02))
            phase += 2 * .pi * f / sampleRate
            let env = exp(-t / decay) * min(t / 0.001, 1)
            out[idx] += Float((sin(phase) + 0.3 * sin(2 * phase)) * env) * amp
        }
    }

    /// 높이가 변하는 음. 배음 목록으로 음색을 정한다.
    private static func addTone(
        _ out: inout [Float], start: Double, dur: Double, from: Double, to: Double,
        amp: Float, decay: Double, harmonics: [Double]
    ) {
        let first = Int(start * sampleRate)
        let count = Int(dur * sampleRate)
        var phase = 0.0
        for k in 0..<count {
            let idx = first + k
            if idx >= out.count { break }
            let t = Double(k) / sampleRate
            let p = t / dur
            let f = from * pow(to / from, min(p * 2.2, 1))
            phase += 2 * .pi * f / sampleRate
            var v = 0.0
            for (h, g) in harmonics.enumerated() { v += sin(phase * Double(h + 1)) * g }
            let env = exp(-t / decay) * min(t / 0.003, 1)
            out[idx] += Float(v * env) * amp
        }
    }

    /// 대역을 제한한 노이즈 한 방울
    private static func addNoise(
        _ out: inout [Float], start: Double, dur: Double, amp: Float,
        lowCut: Double, highCut: Double, decay: Double, seed: UInt64
    ) {
        let first = Int(start * sampleRate)
        let count = Int(dur * sampleRate)
        var noise = NoiseGen(seed: seed)
        var lowFilter = SVF(), highFilter = SVF()
        let fLow = Float(2 * sin(Double.pi * lowCut / sampleRate))
        let fHigh = Float(2 * sin(Double.pi * min(highCut, 6500) / sampleRate))
        for k in 0..<count {
            let idx = first + k
            if idx >= out.count { break }
            let t = Double(k) / sampleRate
            let x = noise.next()
            let bandLimited = lowFilter.process(x, f: fLow, q: 1.2).high
            let shaped = highFilter.process(bandLimited, f: fHigh, q: 1.2).low
            out[idx] += shaped * Float(exp(-t / decay)) * amp
        }
    }

    /// 필터 중심이 `from`에서 `to`로 쓸고 가는 노이즈(바람, 폭발의 꼬리)
    private static func addSweepNoise(
        _ out: inout [Float], start: Double, dur: Double, from: Double, to: Double,
        amp: Float, q: Float, seed: UInt64, decay: Double? = nil
    ) {
        let first = Int(start * sampleRate)
        let count = Int(dur * sampleRate)
        var noise = NoiseGen(seed: seed)
        var filter = SVF()
        for k in 0..<count {
            let idx = first + k
            if idx >= out.count { break }
            let t = Double(k) / sampleRate
            let p = t / dur
            let fc = min(from * pow(to / from, p), 6500)
            let f = Float(2 * sin(Double.pi * fc / sampleRate))
            let band = filter.process(noise.next(), f: f, q: q).band
            let env: Double
            if let decay {
                env = exp(-t / decay) * min(t / 0.004, 1)
            } else {
                env = sin(.pi * p)   // 가운데가 가장 큰 바람 소리
            }
            out[idx] += band * Float(env) * amp
        }
    }

    /// 퍼엉 하고 터지는 한 번의 소리
    private static func addPop(_ out: inout [Float], start: Double, amp: Float, pitch: Double, seed: UInt64) {
        addTone(&out, start: start, dur: 0.22, from: 240 * pitch, to: 80 * pitch, amp: amp * 0.9, decay: 0.07, harmonics: [1, 0.35])
        addNoise(&out, start: start, dur: 0.12, amp: amp * 0.8, lowCut: 500, highCut: 4800, decay: 0.035, seed: seed)
        addNoise(&out, start: start, dur: 0.01, amp: amp * 0.5, lowCut: 3000, highCut: 8000, decay: 0.003, seed: seed &+ 100)
    }

    /// 천천히 차오르고 길게 이어지는 따뜻한 화음 바닥
    private static func addPad(_ out: inout [Float], freqs: [Double], start: Double, dur: Double, amp: Float) {
        let first = Int(start * sampleRate)
        let count = Int(dur * sampleRate)
        for (voice, f) in freqs.enumerated() {
            let w1 = 2 * Double.pi * f / sampleRate
            let w2 = 2 * Double.pi * f * 1.004 / sampleRate
            let g = Double(amp) / Double(freqs.count)
            for k in 0..<count {
                let idx = first + k
                if idx >= out.count { break }
                let t = Double(k) / sampleRate
                let attack = min(t / 0.18, 1)
                let release = exp(-max(t - dur * 0.35, 0) / (dur * 0.28))
                let wobble = 1 + 0.01 * sin(2 * .pi * 4.5 * t + Double(voice))
                let v = (sin(w1 * Double(k)) + 0.6 * sin(w2 * Double(k) * wobble) + 0.2 * sin(2 * w1 * Double(k))) * g
                out[idx] += Float(v * attack * release)
            }
        }
    }

    // MARK: - 마무리

    /// 부드러운 포화로 튀는 값을 누르고, 최대 크기를 맞추고, 양 끝을 서서히 줄여 딱 소리를 막는다.
    private static func finish(_ out: inout [Float], gain: Float) {
        guard !out.isEmpty else { return }
        for i in out.indices { out[i] = tanhf(out[i] * 1.1) }
        let peak = out.reduce(0) { max($0, abs($1)) }
        let scale = peak > 0 ? gain / peak : 1
        let fadeIn = Int(0.002 * sampleRate)
        let fadeOut = min(Int(0.02 * sampleRate), out.count)
        for i in out.indices {
            var s = out[i] * scale
            if i < fadeIn { s *= Float(i) / Float(fadeIn) }
            let remain = out.count - 1 - i
            if remain < fadeOut { s *= Float(remain) / Float(fadeOut) }
            out[i] = s
        }
    }
}

extension FeedbackCue {
    /// 합성 후 맞추는 최대 크기(0...1). 작은 조작음은 낮게, 연출음은 높게 둔다.
    nonisolated var targetPeak: Float {
        switch self {
        case .select, .button: 0.38
        case .confirm, .next: 0.42
        case .hint: 0.45
        case .correct: 0.62
        case .wrong: 0.6
        case .popup: 0.5
        case .chargeUp: 0.7
        case .impact: 0.95
        case .burst: 0.82
        case .reveal: 0.75
        case .treeComplete: 0.8
        }
    }
}

// MARK: - 도구

/// 같은 입력이면 같은 값을 내는 가벼운 난수(xorshift). 소리가 매번 똑같이 합성되도록 쓴다.
nonisolated struct NoiseGen {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 0x9E37_79B9_7F4A_7C15 | 1
    }

    /// -1...1 사이 값
    mutating func next() -> Float {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        let r = state &* 0x2545_F491_4F6C_DD1D
        return Float(Int64(bitPattern: r) >> 11) / Float(1 << 52)
    }
}

/// 상태 변수 필터(저역, 대역, 고역 출력을 한 번에 얻는다). `f`는 `2 sin(π fc / fs)`, `q`는 `1 / Q`.
nonisolated struct SVF {
    private var low: Float = 0
    private var band: Float = 0

    mutating func process(_ x: Float, f: Float, q: Float) -> (low: Float, band: Float, high: Float) {
        let high = x - low - q * band
        band += f * high
        low += f * band
        return (low, band, high)
    }
}
