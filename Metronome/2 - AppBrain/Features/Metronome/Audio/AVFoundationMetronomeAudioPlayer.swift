import AVFoundation
import Dispatch

actor AVFoundationMetronomeAudioPlayer: MetronomeAudioPlayer {
    // Session activation and engine setup are synchronous system calls.
    // This executor keeps them off the Main Actor and cooperative pool.
    private let executor = DispatchSerialQueue(label: "Metronome.audio", qos: .userInitiated)
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }
    private let bundle: Bundle
    private lazy var audioEngine = AVAudioEngine()
    private lazy var playerNode = AVAudioPlayerNode()
    private lazy var rhythmNode = AVAudioPlayerNode()
    private var voices: [AVAudioPlayerNode] = []
    private var voicePool: MetronomeVoicePool?
    private var schedule: MetronomeBeatSchedule?
    private var rhythmClicks: [Bool: AVAudioPCMBuffer] = [:]
    private var refillTask: Task<Void, Never>?
    private var generation = 0
    private var playbackFailure: (any Error)?
    private var skippedBeats: Int64 = 0
    private var committed: [(beat: MetronomeBeatSchedule.Beat, step: Int)] = []
    private var nextStep = 0
    private var audible: MetronomePlaybackProgress?

    private var accentClickFile: AVAudioFile?
    private var normalClickFile: AVAudioFile?
    private var accentClickBuffer: AVAudioPCMBuffer?
    private var normalClickBuffer: AVAudioPCMBuffer?
    private var isPrepared = false
    private var isConnected = false

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    deinit {
        refillTask?.cancel()
    }

    func prepare() throws {
        guard !isPrepared else { return }
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
        if !isConnected {
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
            audioEngine.attach(rhythmNode)
            audioEngine.connect(rhythmNode, to: audioEngine.mainMixerNode,
                                format: AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
            isConnected = true
        }

        accentClickFile = loadSoundFile(named: "accent_click")
        normalClickFile = loadSoundFile(named: "normal_click")
        // Missing bundled sounds are synthesised once, not on every beat.
        if accentClickFile == nil {
            accentClickBuffer = makeClickBuffer(accented: true)
        }
        if normalClickFile == nil {
            normalClickBuffer = makeClickBuffer(accented: false)
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        for accented in [false, true] {
            let samples = try clickSamples(accented: accented)
            let count = samples[0].count
            guard count > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count)),
                  let channels = buffer.floatChannelData else { throw CocoaError(.fileReadCorruptFile) }
            buffer.frameLength = AVAudioFrameCount(count)
            for channel in 0..<2 {
                for frame in 0..<count { channels[channel][frame] = samples[channel][frame] }
            }
            rhythmClicks[accented] = buffer
        }
        let longest = rhythmClicks.values.map { Int($0.frameLength) }.max() ?? 0
        let capacity = (longest + 440) / 441 + 1
        voicePool = try MetronomeVoicePool(capacity: capacity)
        // Preparation may be retried after failure; never attach duplicate voices.
        while voices.count < capacity {
            let node = AVAudioPlayerNode()
            audioEngine.attach(node)
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: format)
            voices.append(node)
        }
        try audioEngine.start()
        isPrepared = true
    }

    func startIfNeeded() throws {
        try prepare()

        if !audioEngine.isRunning {
            try audioEngine.start()
        }

        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    func stop() {
        generation += 1
        refillTask?.cancel()
        refillTask = nil
        schedule = nil
        committed.removeAll()
        audible = nil
        nextStep = 0
        voicePool?.reset()
        guard isConnected else { return }
        playerNode.stop()
        rhythmNode.stop()
        voices.forEach { $0.stop() }
    }

    func schedulePlayback(_ pattern: MetronomePlaybackPattern, initialDelay: Double) throws {
        try prepare()
        _ = try pattern.framesPerBeat(sampleRate: 44_100)
        if schedule != nil {
            try schedule?.update(pattern)
            return
        }
        playbackFailure = nil
        skippedBeats = 0
        schedule = try MetronomeBeatSchedule(pattern: pattern, sampleRate: 44_100)
        // A silent clock keeps every voice on the same continuous player timeline,
        // including when all musical beats are silent.
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 441),
              let channels = buffer.floatChannelData else { throw CocoaError(.fileReadCorruptFile) }
        buffer.frameLength = 441
        for channel in 0..<2 {
            for frame in 0..<441 { channels[channel][frame] = 0 }
        }
        if !audioEngine.isRunning { try audioEngine.start() }
        rhythmNode.scheduleBuffer(buffer, at: nil, options: .loops)
        try refill(from: 0)
        let hostTime = mach_absolute_time() + AVAudioTime.hostTime(forSeconds: max(0.04, initialDelay))
        let start = AVAudioTime(hostTime: hostTime)
        rhythmNode.play(at: start)
        voices.forEach { $0.play(at: start) }
        let generation = self.generation
        refillTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(20))
                    try Task.checkCancellation()
                    guard let self else { return }
                    try await self.refillAheadOfPlayhead(generation: generation)
                } catch is CancellationError {
                    return
                } catch {
                    await self?.failPlayback(error, generation: generation)
                    return
                }
            }
        }
    }

    func playbackBeat() -> Int? {
        updateAudibleBeat()
        return audible?.step
    }

    func playbackProgress() async throws -> MetronomePlaybackProgress? {
        if let playbackFailure { throw playbackFailure }
        updateAudibleBeat()
        guard let audible else { return nil }
        return MetronomePlaybackProgress(step: audible.step, beatIndex: audible.beatIndex, skippedBeats: skippedBeats)
    }

    private func currentSample() -> Int64? {
        guard schedule != nil, rhythmNode.isPlaying,
              let renderTime = rhythmNode.lastRenderTime,
              let time = rhythmNode.playerTime(forNodeTime: renderTime), time.sampleTime >= 0 else { return nil }
        return time.sampleTime
    }

    private func updateAudibleBeat() {
        guard let sample = currentSample() else { return }
        while let first = committed.first, first.beat.sampleTime <= sample {
            audible = MetronomePlaybackProgress(step: first.step, beatIndex: first.beat.index, skippedBeats: skippedBeats)
            committed.removeFirst()
        }
    }

    private func refillAheadOfPlayhead(generation: Int) throws {
        guard generation == self.generation, !Task.isCancelled, let sample = currentSample() else { return }
        updateAudibleBeat()
        // Ten milliseconds of scheduling lead; one hundred milliseconds ahead.
        // These are initial tuning values, not a measured device-performance claim.
        try refill(from: sample + 441)
    }

    private func refill(from sample: Int64) throws {
        guard let window = try schedule?.refill(from: sample, lookAheadFrames: 4410) else { return }
        skippedBeats += window.skippedBeats
        nextStep += Int(window.skippedBeats)
        for beat in window.beats {
            if let accent = beat.accented, let buffer = rhythmClicks[accent] {
                guard let voice = try voicePool?.reserve(at: beat.sampleTime, frameCount: Int64(buffer.frameLength)) else {
                    throw CocoaError(.coderInvalidValue)
                }
                voices[voice].scheduleBuffer(buffer, at: AVAudioTime(sampleTime: beat.sampleTime, atRate: 44_100))
            }
            committed.append((beat, nextStep))
            nextStep += 1
        }
    }

    private func failPlayback(_ error: any Error, generation: Int) {
        guard generation == self.generation else { return }
        stop()
        playbackFailure = error
    }

    private var cachedClickSamples: [Bool: [[Float]]] = [:]

    private func clickSamples(accented: Bool) throws -> [[Float]] {
        if let cached = cachedClickSamples[accented] { return cached }
        let file = accented ? accentClickFile : normalClickFile
        let buffer: AVAudioPCMBuffer
        if let file {
            guard file.processingFormat.sampleRate == 44_100,
                  let loaded = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                              frameCapacity: AVAudioFrameCount(file.length)) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            file.framePosition = 0
            try file.read(into: loaded)
            buffer = loaded
        } else if let fallback = accented ? accentClickBuffer : normalClickBuffer {
            buffer = fallback
        } else { throw CocoaError(.fileReadCorruptFile) }
        guard let data = buffer.floatChannelData else { throw CocoaError(.fileReadCorruptFile) }
        let samples = (0..<2).map { channel in
            Array(UnsafeBufferPointer(start: data[min(channel, Int(buffer.format.channelCount) - 1)],
                                      count: Int(buffer.frameLength)))
        }
        cachedClickSamples[accented] = samples
        return samples
    }

    func playClick(accented: Bool) throws {
        try startIfNeeded()

        let audioFile = accented ? accentClickFile : normalClickFile
        if let audioFile {
            playerNode.scheduleFile(audioFile, at: nil)
        } else if let buffer = accented ? accentClickBuffer : normalClickBuffer {
            playerNode.scheduleBuffer(buffer, at: nil)
        } else {
            throw NSError(domain: "MetronomeAudio", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create the metronome click sound."])
        }
    }

    private func loadSoundFile(named name: String) -> AVAudioFile? {
        guard let url = bundle.url(forResource: name, withExtension: "wav") else {
            return nil
        }

        do {
            return try AVAudioFile(forReading: url)
        } catch {
            print("Failed to load \(name).wav: \(error)")
            return nil
        }
    }

    private func makeClickBuffer(accented: Bool) -> AVAudioPCMBuffer? {
        let sampleRate = 44_100.0
        let duration = 0.1
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ), let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ), let channelData = buffer.floatChannelData?[0] else {
            return nil
        }

        buffer.frameLength = frameCount
        let frequency: Float = accented ? 800 : 400

        for frame in 0..<Int(frameCount) {
            let value = sin(
                2.0 * Float.pi * frequency * Float(frame) / Float(sampleRate)
            ) * 0.5
            channelData[frame] = value * Float(1.0 - Double(frame) / Double(frameCount))
        }

        return buffer
    }
}
