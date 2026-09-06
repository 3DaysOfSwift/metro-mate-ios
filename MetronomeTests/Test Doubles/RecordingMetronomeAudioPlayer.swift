@testable import Metronome

final class RecordingMetronomeAudioPlayer: MetronomeAudioPlayer {
    private(set) var prepareCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var playedAccents: [Bool] = []
    var failure: Error?

    func prepare() throws {
        prepareCallCount += 1
        if let failure { throw failure }
    }

    func startIfNeeded() throws {
        startCallCount += 1
        if let failure { throw failure }
    }

    func stop() {
        stopCallCount += 1
    }

    func playClick(accented: Bool) throws {
        if let failure { throw failure }
        playedAccents.append(accented)
    }
}
