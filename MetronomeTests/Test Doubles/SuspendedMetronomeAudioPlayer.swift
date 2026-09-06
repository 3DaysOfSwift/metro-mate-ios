@testable import Metronome

@MainActor
final class SuspendedMetronomeAudioPlayer: MetronomeAudioPlayer {
    enum Operation { case prepare, start, click }
    var suspendedOperation: Operation?
    private let arrivals = AsyncStream<Operation>.makeStream()
    private var pending: CheckedContinuation<Void, Never>?
    private(set) var commands: [String] = []
    func schedulePlayback(_ pattern: MetronomePlaybackPattern, initialDelay: Double) {}
    func playbackBeat() -> Int? { nil }

    func prepare() async throws {
        commands.append("prepare")
        await suspendIfRequested(.prepare)
    }

    func startIfNeeded() async throws {
        commands.append("start")
        await suspendIfRequested(.start)
    }

    func playClick(accented: Bool) async throws {
        commands.append("click")
        await suspendIfRequested(.click)
    }

    func stop() { commands.append("stop") }

    private func suspendIfRequested(_ operation: Operation) async {
        guard suspendedOperation == operation else { return }
        await withCheckedContinuation {
            pending = $0
            arrivals.continuation.yield(operation)
        }
    }

    func waitForSuspension() async {
        var events = arrivals.stream.makeAsyncIterator()
        _ = await events.next()
    }

    func finishOperation() {
        suspendedOperation = nil
        let continuation = pending
        pending = nil
        continuation?.resume()
    }
}
