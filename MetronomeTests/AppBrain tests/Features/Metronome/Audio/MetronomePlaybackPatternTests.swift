import Testing
import AVFoundation
@testable import Metronome

struct MetronomePlaybackPatternTests {
    @Test func audioEngineLoopsAtSampleSpacedIntervalsWithoutUITicks() async throws {
        let rendered = try await OfflineRhythmProbe().render()
        let peaks = rendered.enumerated().filter { abs($0.element) > 0.1 }.map(\.offset)
        #expect(peaks.count >= 5)
        for pair in zip(peaks, peaks.dropFirst()) {
            #expect(pair.1 - pair.0 == 441)
        }
    }
    @Test func renderedClicksOccupyExactSampleOffsetsIncludingSilence() throws {
        let pattern = MetronomePlaybackPattern(interval: 0.25, beats: [true, nil, false, false], restartFromFirstBeat: true)
        let samples = try pattern.render(normal: [[0.4], [0.4]], accented: [[0.8], [0.8]], sampleRate: 100, firstBeat: 0)
        #expect(samples.count == 2)
        #expect(samples[0].count == 100)
        #expect(samples[0].enumerated().filter { $0.element != 0 }.map(\.offset) == [0, 50, 75])
        #expect(samples[0][0] == 0.8)
        #expect(samples[0][50] == 0.4)
        #expect(samples[0] == samples[1])
    }

    @Test func shortSubdivisionsMixTailsInsteadOfDelayingTheNextClick() throws {
        let pattern = MetronomePlaybackPattern(interval: 0.02, beats: [false, false], restartFromFirstBeat: true)
        let samples = try pattern.render(normal: [[0.2, 0, 0.1], [0.2, 0, 0.1]], accented: [[], []], sampleRate: 100, firstBeat: 0)
        #expect(samples[0].count == 4)
        #expect(abs(samples[0][0] - 0.3) < 0.0001)
        #expect(abs(samples[0][2] - 0.3) < 0.0001)
    }

    @Test func replacementCanBeginAtTheNextBeatWithoutChangingThePatternOrder() throws {
        let pattern = MetronomePlaybackPattern(interval: 0.1, beats: [true, nil, false], restartFromFirstBeat: false)
        let samples = try pattern.render(normal: [[0.4], [0.4]], accented: [[0.8], [0.8]], sampleRate: 100, firstBeat: 1)
        #expect(samples[0][0] == 0)
        #expect(samples[0][10] == 0.4)
        #expect(samples[0][20] == 0.8)
    }

    @Test func invalidTimingIsRejectedBeforeAllocatingAudio() {
        let pattern = MetronomePlaybackPattern(interval: .infinity, beats: [true], restartFromFirstBeat: true)
        #expect(throws: (any Error).self) { try pattern.framesPerBeat(sampleRate: 44_100) }
    }
}

/// Exercises AVAudioPlayerNode looping, without a device audio session or UI timer.
private actor OfflineRhythmProbe {
    func render() throws -> [Float] {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
        let pattern = MetronomePlaybackPattern(interval: 0.01, beats: [true, false], restartFromFirstBeat: true)
        let samples = try pattern.render(normal: [[0.4], [0.4]], accented: [[0.8], [0.8]], sampleRate: 44_100, firstBeat: 0)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 882))
        buffer.frameLength = 882
        let data = try #require(buffer.floatChannelData)
        for channel in 0..<2 {
            for index in 0..<882 { data[channel][index] = samples[channel][index] }
        }
        let engine = AVAudioEngine()
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 256)
        node.scheduleBuffer(buffer, at: nil, options: .loops)
        try engine.start()
        node.play()
        defer { node.stop(); engine.stop() }
        let output = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256))
        var result: [Float] = []
        for _ in 0..<12 {
            let status = try engine.renderOffline(256, to: output)
            try #require(status == .success)
            let channel = try #require(output.floatChannelData?[0])
            result.append(contentsOf: UnsafeBufferPointer(start: channel, count: Int(output.frameLength)))
        }
        return result
    }
}
