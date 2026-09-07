import Testing
@testable import Metronome

struct MetronomePlaybackPatternTests {
    @Test func invalidTimingIsRejectedBeforeAllocatingAudio() {
        for interval in [Double.infinity, .nan, -1, 0, 11] {
            let pattern = MetronomePlaybackPattern(interval: interval, beats: [true], restartFromFirstBeat: true)
            #expect(throws: (any Error).self) { try pattern.framesPerBeat(sampleRate: 44_100) }
        }
    }

    @Test func invalidPatternsAndSampleRatesAreRejected() {
        let invalidPatterns: [[Bool?]] = [[], Array(repeating: true, count: 65)]
        for beats in invalidPatterns {
            let pattern = MetronomePlaybackPattern(interval: 0.1, beats: beats, restartFromFirstBeat: true)
            #expect(throws: (any Error).self) { try pattern.framesPerBeat(sampleRate: 44_100) }
        }
        let pattern = MetronomePlaybackPattern(interval: 0.1, beats: [true], restartFromFirstBeat: true)
        for rate in [0.0, -1, .infinity, .nan, 192_001] {
            #expect(throws: (any Error).self) { try pattern.framesPerBeat(sampleRate: rate) }
        }
    }
}
