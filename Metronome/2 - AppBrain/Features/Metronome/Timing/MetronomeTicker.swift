@MainActor
protocol MetronomeTicker: AnyObject {
    func start(
        after initialDelay: Duration,
        repeatingEvery interval: Duration,
        tick: @escaping @MainActor () async -> Void
    )
    func stop()
}
