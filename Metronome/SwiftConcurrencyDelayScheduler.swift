@MainActor
final class SwiftConcurrencyDelayScheduler: CancellableDelayScheduler {
    private let clock = ContinuousClock()
    private var scheduledTask: Task<Void, Never>?

    func schedule(
        after delay: Duration,
        action: @escaping @MainActor () -> Void
    ) {
        cancel()

        scheduledTask = Task { [clock] in
            do {
                try await clock.sleep(for: delay, tolerance: .zero)
                try Task.checkCancellation()
                action()
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
    }

    func cancel() {
        scheduledTask?.cancel()
        scheduledTask = nil
    }

    deinit {
        scheduledTask?.cancel()
    }
}
