@MainActor
final class AppBrain {
    static let shared = AppBrain.live()

    let metronome: any MetronomeFeature

    init(metronome: any MetronomeFeature) {
        self.metronome = metronome
    }

    /// Produces the live, non-test AppBrain and constructs all production dependencies in one place.
    static func live() -> AppBrain {
        AppBrain(metronome: MetronomeManager())
    }
}
