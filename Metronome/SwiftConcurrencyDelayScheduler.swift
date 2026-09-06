@MainActor
final class SwiftConcurrencyDelayScheduler: CancellableDelayScheduler {
    private let clock = ContinuousClock()
    private var nextTaskID = 0
    private var scheduledTasks: [Int: Task<Void, Never>] = [:]

    func schedule(
        after delay: Duration,
        action: @escaping @MainActor () -> Void
    ) {
        let taskID = nextTaskID
        nextTaskID += 1

        scheduledTasks[taskID] = Task { [weak self, clock] in
            do {
                try await clock.sleep(for: delay, tolerance: .zero)
                try Task.checkCancellation()
                action()
            } catch is CancellationError {
            } catch {
            }

            self?.scheduledTasks[taskID] = nil
        }
    }

    func cancel() {
        scheduledTasks.values.forEach { $0.cancel() }
        scheduledTasks.removeAll()
    }

    deinit {
        scheduledTasks.values.forEach { $0.cancel() }
    }
}
