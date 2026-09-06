@MainActor
final class SwiftConcurrencyMetronomeTicker: MetronomeTicker {
    private let clock = ContinuousClock()
    private var tickingTask: Task<Void, Never>?

    func start(
        after initialDelay: Duration,
        repeatingEvery interval: Duration,
        tick: @escaping @MainActor () async -> Void
    ) {
        stop()

        tickingTask = Task { [clock] in
            var nextTick = clock.now.advanced(by: initialDelay)

            do {
                while !Task.isCancelled {
                    try await clock.sleep(until: nextTick, tolerance: .zero)
                    try Task.checkCancellation()
                    await tick()
                    // Preserve the original cadence: advance from the planned
                    // deadline, not completion time. Overdue ticks may catch up
                    // in a burst; callbacks are awaited and never overlap here.
                    nextTick = nextTick.advanced(by: interval)
                }
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
    }

    func stop() {
        tickingTask?.cancel()
        tickingTask = nil
    }

    deinit {
        tickingTask?.cancel()
    }
}
