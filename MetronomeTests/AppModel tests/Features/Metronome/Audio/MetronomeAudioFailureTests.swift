import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct MetronomeAudioFailureTests {
    @Test func audioFailureDoesNotStartPlaybackAndCanBeRetried() async {
        enum Failure: Error { case unavailable }
        let audio = RecordingMetronomeAudioPlayer()
        let ticker = ControllableMetronomeTicker()
        let manager = makeTestMetronome(audioPlayer: audio, ticker: ticker)
        audio.failure = Failure.unavailable
        await manager.prepareAudio()
        #expect(manager.audioError != nil)
        await manager.togglePlayback()
        #expect(!manager.isPlaying)
        #expect(ticker.startCallCount == 0)
        audio.failure = nil
        await manager.prepareAudio()
        #expect(manager.audioError == nil)
        await manager.togglePlayback()
        #expect(manager.isPlaying)
        audio.failure = Failure.unavailable
        await manager.tapTempo()
        #expect(!manager.isPlaying)
        #expect(manager.audioError != nil)
    }
}
