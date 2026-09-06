@MainActor
final class SwiftConcurrencyMetronomeTicker: MetronomeTicker {
    private let clock = ContinuousClock()
    private var tickingTask: Task<Void, Never>?

    func start(
        after initialDelay: Duration,
        repeatingEvery interval: Duration,
        tick: @escaping @MainActor () -> Void
    ) {
        stop()

        tickingTask = Task { [clock] in
            var nextTick = clock.now.advanced(by: initialDelay)

            do {
                while !Task.isCancelled {
                    try await clock.sleep(until: nextTick, tolerance: .zero)
                    try Task.checkCancellation()
                    tick()
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

