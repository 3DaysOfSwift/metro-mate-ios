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
    private lazy var rhythmTempo = AVAudioUnitTimePitch()
    private var rhythmPattern: MetronomePlaybackPattern?
    private var rhythmFirstBeat = 0
    private var rhythmFramesPerBeat = 1
    private var rhythmBuffer: AVAudioPCMBuffer?

    private var accentClickFile: AVAudioFile?
    private var normalClickFile: AVAudioFile?
    private var accentClickBuffer: AVAudioPCMBuffer?
    private var normalClickBuffer: AVAudioPCMBuffer?
    private var isPrepared = false
    private var isConnected = false

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func prepare() throws {
        guard !isPrepared else { return }
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
        if !isConnected {
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
            audioEngine.attach(rhythmNode)
            audioEngine.attach(rhythmTempo)
            audioEngine.connect(rhythmNode, to: rhythmTempo,
                                format: AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
            audioEngine.connect(rhythmTempo, to: audioEngine.mainMixerNode,
                                format: AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
            isConnected = true
        }
        try audioEngine.start()

        accentClickFile = loadSoundFile(named: "accent_click")
        normalClickFile = loadSoundFile(named: "normal_click")
        // Missing bundled sounds are synthesised once, not on every beat.
        if accentClickFile == nil {
            accentClickBuffer = makeClickBuffer(accented: true)
        }
        if normalClickFile == nil {
            normalClickBuffer = makeClickBuffer(accented: false)
        }
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
        guard isConnected else { return }
        playerNode.stop()
        rhythmNode.stop()
        rhythmPattern = nil
        rhythmBuffer = nil
    }

    func schedulePlayback(_ pattern: MetronomePlaybackPattern, initialDelay: Double) throws {
        try prepare()
        let framesPerBeat = try pattern.framesPerBeat(sampleRate: 44_100)
        // Keep the source loop and its sample timeline intact for tempo-only edits.
        // The source pattern remains the reference: successive rates must not compound.
        if rhythmNode.isPlaying, let source = rhythmPattern,
           let rate = pattern.playbackRate(relativeTo: source) {
            rhythmTempo.rate = rate
            return
        }
        let firstBeat = pattern.restartFromFirstBeat ? 0
            : ((playbackBeat() ?? -1) + 1) % pattern.beats.count
        let frameCount = framesPerBeat * pattern.beats.count
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)),
              let channels = buffer.floatChannelData else { throw CocoaError(.fileReadCorruptFile) }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        let samples = try pattern.render(normal: clickSamples(accented: false),
                                         accented: clickSamples(accented: true),
                                         sampleRate: 44_100, firstBeat: firstBeat)
        for channel in 0..<2 {
            for frame in 0..<frameCount { channels[channel][frame] = samples[channel][frame] }
        }
        if !audioEngine.isRunning { try audioEngine.start() }
        rhythmNode.stop()
        rhythmTempo.rate = 1
        rhythmPattern = pattern
        rhythmFirstBeat = firstBeat
        rhythmFramesPerBeat = framesPerBeat
        rhythmBuffer = buffer
        rhythmNode.scheduleBuffer(buffer, at: nil, options: .loops)
        let hostTime = mach_absolute_time() + AVAudioTime.hostTime(forSeconds: max(0, initialDelay))
        rhythmNode.play(at: AVAudioTime(hostTime: hostTime))
    }

    func playbackBeat() -> Int? {
        guard rhythmPattern != nil, rhythmNode.isPlaying,
              let renderTime = rhythmNode.lastRenderTime,
              let time = rhythmNode.playerTime(forNodeTime: renderTime), time.sampleTime >= 0 else { return nil }
        return rhythmFirstBeat + Int(time.sampleTime) / rhythmFramesPerBeat
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
