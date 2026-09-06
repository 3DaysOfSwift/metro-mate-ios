import AVFoundation

final class AVFoundationMetronomeAudioPlayer: MetronomeAudioPlayer {
    private let bundle: Bundle
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    private var accentClickFile: AVAudioFile?
    private var normalClickFile: AVAudioFile?
    private var isPrepared = false

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func prepare() {
        guard !isPrepared else { return }
        isPrepared = true

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }

        accentClickFile = loadSoundFile(named: "accent_click")
        normalClickFile = loadSoundFile(named: "normal_click")
    }

    func startIfNeeded() {
        prepare()

        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("Failed to restart audio engine: \(error)")
            }
        }

        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    func stop() {
        playerNode.stop()
    }

    func playClick(accented: Bool) {
        startIfNeeded()

        let audioFile = accented ? accentClickFile : normalClickFile
        if let audioFile {
            playerNode.scheduleFile(audioFile, at: nil)
        } else if let buffer = makeClickBuffer(accented: accented) {
            playerNode.scheduleBuffer(buffer, at: nil)
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

