@testable import Metronome

@MainActor
final class ControllableMetronomeTicker: MetronomeTicker {
    private(set) var initialDelay: Duration?
    private(set) var interval: Duration?
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    private var tick: (@MainActor () -> Void)?

    func start(
        after initialDelay: Duration,
        repeatingEvery interval: Duration,
        tick: @escaping @MainActor () -> Void
    ) {
        self.initialDelay = initialDelay
        self.interval = interval
        self.tick = tick
        startCallCount += 1
    }

    func stop() {
        tick = nil
        stopCallCount += 1
    }

    func sendTick() {
        tick?()
    }
}
