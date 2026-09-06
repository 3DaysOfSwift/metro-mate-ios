@MainActor
protocol CancellableDelayScheduler: AnyObject {
    func schedule(
        after delay: Duration,
        action: @escaping @MainActor () -> Void
    )
    func cancel()
}
