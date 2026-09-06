@testable import Metronome

@MainActor
final class RecordingMetronomeAudioPlayer: MetronomeAudioPlayer {
    private(set) var prepareCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var playedAccents: [Bool] = []
    var failure: Error?
    var currentPlaybackBeat: Int?
    private(set) var scheduledPatterns: [MetronomePlaybackPattern] = []
    private let schedules = AsyncStream<Void>.makeStream()

    func schedulePlayback(_ pattern: MetronomePlaybackPattern, initialDelay: Double) throws {
        if let failure { throw failure }
        scheduledPatterns.append(pattern)
        schedules.continuation.yield()
    }

    func waitForSchedule() async {
        var events = schedules.stream.makeAsyncIterator()
        _ = await events.next()
    }

    func playbackBeat() -> Int? { currentPlaybackBeat }

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
