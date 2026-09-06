@testable import Metronome

@MainActor
final class ControllableDelayScheduler: CancellableDelayScheduler {
    private(set) var delays: [Duration] = []
    private(set) var cancelCallCount = 0

    private var actions: [@MainActor () -> Void] = []

    func schedule(
        after delay: Duration,
        action: @escaping @MainActor () -> Void
    ) {
        delays.append(delay)
        actions.append(action)
    }

    func cancel() {
        delays.removeAll()
        actions.removeAll()
        cancelCallCount += 1
    }

    func completeAllDelays() {
        let actions = actions
        delays.removeAll()
        self.actions.removeAll()
        actions.forEach { $0() }
    }
}
