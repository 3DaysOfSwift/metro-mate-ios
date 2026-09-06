@testable import Metronome

@MainActor
final class ControllableDelayScheduler: CancellableDelayScheduler {
    private(set) var delay: Duration?
    private(set) var cancelCallCount = 0

    private var action: (@MainActor () -> Void)?

    func schedule(
        after delay: Duration,
        action: @escaping @MainActor () -> Void
    ) {
        self.delay = delay
        self.action = action
    }

    func cancel() {
        action = nil
        cancelCallCount += 1
    }

    func completeDelay() {
        let action = action
        self.action = nil
        action?()
    }
}
