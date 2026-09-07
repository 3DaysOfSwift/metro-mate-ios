import AVFoundation
import Testing
@testable import Metronome

struct MetronomeBeatScheduleTests {
    @Test func refillsAreBoundedAndNeverDuplicateAlreadyCommittedBeats() throws {
        var schedule = try MetronomeBeatSchedule(pattern: pattern(0.01), sampleRate: 44_100)
        let first = try schedule.refill(from: 0, lookAheadFrames: 11_025)
        #expect(first.beats.count == 25)
        #expect(first.skippedBeats == 0)
        #expect(try schedule.refill(from: 0, lookAheadFrames: 11_025).beats.isEmpty)
        #expect(throws: (any Error).self) { try schedule.refill(from: 0, lookAheadFrames: 11_026) }
    }

    @Test func delayedRefillSkipsExpiredBeatsWithoutACatchUpBurst() throws {
        var schedule = try MetronomeBeatSchedule(pattern: pattern(0.1), sampleRate: 100)
        #expect(try schedule.refill(from: 0, lookAheadFrames: 20).beats.map(\.sampleTime) == [0, 10])
        let resumed = try schedule.refill(from: 105, lookAheadFrames: 20)
        #expect(resumed.skippedBeats == 9)
        #expect(resumed.beats.map(\.sampleTime) == [110, 120])
        #expect(resumed.beats.map(\.index) == [1, 0])
    }

    @Test func fixedVoicePoolReusesFinishedVoicesWithoutCuttingTails() throws {
        var pool = try MetronomeVoicePool(capacity: 2)
        #expect(try pool.reserve(at: 0, frameCount: 600) == 0)
        #expect(try pool.reserve(at: 441, frameCount: 600) == 1)
        #expect(throws: (any Error).self) { try pool.reserve(at: 500, frameCount: 600) }
        #expect(try pool.reserve(at: 882, frameCount: 600) == 0)
        #expect(pool.capacity == 2)
        pool.reset()
        #expect(try pool.reserve(at: 0, frameCount: 600) == 0)
    }

    @Test func engineMixesOverlappingTailsUsingAReusableVoicePool() async throws {
        var schedule = try MetronomeBeatSchedule(pattern: pattern(0.01), sampleRate: 44_100)
        let beats = try schedule.refill(from: 0, lookAheadFrames: 4410).beats
        let samples = try await ScheduledClickProbe().render(beats, clickLength: 600)
        // Tail marker from beat zero overlaps beat one, without postponing it.
        #expect(abs(samples[500] - 0.15) < 0.0001)
        #expect(abs(samples[441] - 0.4) < 0.0001)
        #expect(abs(samples[882] - 0.8) < 0.0001)
        #expect(abs(samples[941] - 0.15) < 0.0001)
    }

    @Test func rapidEditsReplacePendingTempoWithoutMovingTheNextBeat() throws {
        var schedule = try MetronomeBeatSchedule(pattern: pattern(0.1), sampleRate: 44_100)
        #expect(schedule.commit(until: 4411).map(\.sampleTime) == [0, 4410])
        for interval in [0.09, 0.08, 0.07, 0.05] {
            try schedule.update(pattern(interval))
        }
        let beats = schedule.commit(until: 15_436)
        #expect(beats.map(\.sampleTime) == [8820, 11025, 13230, 15435])
        #expect(beats.map(\.index) == [0, 1, 0, 1])
    }

    @Test func deadlinesDoNotAccumulateRoundedIntervalError() throws {
        var schedule = try MetronomeBeatSchedule(pattern: pattern(60.0 / 137), sampleRate: 44_100)
        let beats = schedule.commit(until: 441_000)
        for (index, beat) in beats.enumerated() {
            #expect(abs(Double(beat.sampleTime) - Double(index) * 60 / 137 * 44_100) <= 0.5)
        }
    }

    @Test func patternChangesPreserveSilenceAndApplyRestartOnlyAtTheUncommittedBeat() throws {
        var schedule = try MetronomeBeatSchedule(pattern: pattern(0.1), sampleRate: 100)
        #expect(schedule.commit(until: 1).count == 1)
        try schedule.update(MetronomePlaybackPattern(interval: 0.1, beats: [nil, true, false], restartFromFirstBeat: true))
        let beats = schedule.commit(until: 31)
        #expect(beats.map(\.sampleTime) == [10, 20, 30])
        #expect(beats.map(\.accented) == [nil, true, false])
    }

    @Test func renderedTempoEditPreservesTheOriginalClickSamples() async throws {
        var schedule = try MetronomeBeatSchedule(pattern: pattern(0.1), sampleRate: 44_100)
        var beats = schedule.commit(until: 4411)
        try schedule.update(pattern(0.05))
        beats += schedule.commit(until: 15_436)
        let samples = try await ScheduledClickProbe().render(beats)
        let expectedOnsets = beats.map { Int($0.sampleTime) }
        #expect(samples.enumerated().filter { abs($0.element) > 0.3 }.map(\.offset) == expectedOnsets)
        for beat in beats {
            let start = Int(beat.sampleTime)
            #expect(abs(samples[start] - (beat.accented == true ? 0.8 : 0.4)) < 0.0001)
            #expect(abs(samples[start + 1] - 0.2) < 0.0001)
            #expect(abs(samples[start + 2] + 0.1) < 0.0001)
        }
    }

    private func pattern(_ interval: Double) -> MetronomePlaybackPattern {
        MetronomePlaybackPattern(interval: interval, beats: [true, false], restartFromFirstBeat: false)
    }
}

/// Finite offline probe using the candidate deadline and voice-reservation policies.
/// Refill task lifetime and UI publication are not simulated here.
private actor ScheduledClickProbe {
    func render(_ beats: [MetronomeBeatSchedule.Beat], clickLength: Int = 3) throws -> [Float] {
        let engine = AVAudioEngine()
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
        var nodes: [AVAudioPlayerNode] = []
        var pool = try MetronomeVoicePool(capacity: 2)
        for _ in 0..<pool.capacity {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            nodes.append(node)
        }
        for beat in beats {
            guard let accented = beat.accented else { continue }
            let voice = try pool.reserve(at: beat.sampleTime, frameCount: Int64(clickLength))
            let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(clickLength)))
            buffer.frameLength = AVAudioFrameCount(clickLength)
            let data = try #require(buffer.floatChannelData)
            for channel in 0..<2 {
                for frame in 0..<clickLength { data[channel][frame] = 0 }
                data[channel][0] = accented ? 0.8 : 0.4
                data[channel][1] = 0.2
                data[channel][2] = -0.1
                if clickLength > 500 { data[channel][500] = 0.15 }
            }
            nodes[voice].scheduleBuffer(buffer, at: AVAudioTime(sampleTime: beat.sampleTime, atRate: 44_100))
        }
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 512)
        try engine.start()
        nodes.forEach { $0.play() }
        defer { nodes.forEach { $0.stop() }; engine.stop() }
        let output = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512))
        var samples: [Float] = []
        while samples.count < 16_384 {
            let status = try engine.renderOffline(512, to: output)
            try #require(status == .success)
            let data = try #require(output.floatChannelData?[0])
            samples.append(contentsOf: UnsafeBufferPointer(start: data, count: Int(output.frameLength)))
        }
        return samples
    }
}
