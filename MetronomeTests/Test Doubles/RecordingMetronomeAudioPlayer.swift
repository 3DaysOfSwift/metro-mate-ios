@testable import Metronome

final class RecordingMetronomeAudioPlayer: MetronomeAudioPlayer {
    private(set) var prepareCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var playedAccents: [Bool] = []

    func prepare() {
        prepareCallCount += 1
    }

    func startIfNeeded() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }

    func playClick(accented: Bool) {
        playedAccents.append(accented)
    }
}
