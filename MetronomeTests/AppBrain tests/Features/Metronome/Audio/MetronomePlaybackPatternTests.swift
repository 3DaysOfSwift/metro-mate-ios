import Testing
import AVFoundation
@testable import Metronome

struct MetronomePlaybackPatternTests {
    @Test func audioEngineKeepsRenderingThroughRepeatedRateChanges() async throws {
        let energies = try await OfflineRhythmProbe().renderRateChanges()
        // After warm-up, repeated edits must not insert a beat-sized silent gap.
        #expect(energies.count == 100)
        #expect(energies.allSatisfy { $0.isFinite && $0 > 0.001 })
    }

    @Test func repeatedTempoRatesReferToTheOriginalLoopRatherThanCompounding() {
        let source = MetronomePlaybackPattern(interval: 0.5, beats: [true, false], restartFromFirstBeat: true)
        for bpm in 40...200 {
            let next = MetronomePlaybackPattern(interval: 30.0 / Double(bpm), beats: source.beats, restartFromFirstBeat: false)
            #expect(next.playbackRate(relativeTo: source) == Float(Double(bpm) / 60.0))
        }
        let restart = MetronomePlaybackPattern(interval: 0.25, beats: source.beats, restartFromFirstBeat: true)
        #expect(restart.playbackRate(relativeTo: source) == nil)
        let changed = MetronomePlaybackPattern(interval: 0.25, beats: [nil, false], restartFromFirstBeat: false)
        #expect(changed.playbackRate(relativeTo: source) == nil)
    }

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
    func renderRateChanges() throws -> [Float] {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
        let engine = AVAudioEngine()
        let node = AVAudioPlayerNode()
        let tempo = AVAudioUnitTimePitch()
        engine.attach(node)
        engine.attach(tempo)
        engine.connect(node, to: tempo, format: format)
        engine.connect(tempo, to: engine.mainMixerNode, format: format)
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 512)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4410))
        buffer.frameLength = 4410
        let data = try #require(buffer.floatChannelData)
        // A continuous tone makes unintended silence unambiguous, unlike silent
        // spaces deliberately included in the metronome's musical pattern.
        for channel in 0..<2 {
            for frame in 0..<4410 {
                data[channel][frame] = 0.25 * sin(2 * .pi * Float(frame) / 100)
            }
        }
        node.scheduleBuffer(buffer, at: nil, options: .loops)
        try engine.start()
        node.play()
        defer { node.stop(); engine.stop() }
        let output = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512))
        var energies: [Float] = []
        for step in 0..<200 {
            if step >= 100 { tempo.rate = Float(60 + step - 100) / 60 }
            let status = try engine.renderOffline(512, to: output)
            try #require(status == .success)
            if step >= 100 {
                let samples = try #require(output.floatChannelData?[0])
                let energy = (0..<Int(output.frameLength)).reduce(Float.zero) { $0 + samples[$1] * samples[$1] }
                energies.append(energy / Float(output.frameLength))
            }
        }
        return energies
    }

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
