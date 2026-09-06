import Foundation

@MainActor
final class AppBrain {
    static let shared = AppBrain.live()

    let metronome: any MetronomeFeature

    init(metronome: any MetronomeFeature) {
        self.metronome = metronome
    }

    /// Produces the live, non-test AppBrain and constructs all production dependencies in one place.
    static func live() -> AppBrain {
        let presetRepository = UserDefaultsPresetRepository(
            userDefaults: .standard,
            storageKey: "savedBeatPresets"
        )
        let audioPlayer = AVFoundationMetronomeAudioPlayer(bundle: .main)
        let ticker = SwiftConcurrencyMetronomeTicker()
        let tapResetScheduler = SwiftConcurrencyDelayScheduler()
        let metronome = MetronomeManager(
            presetRepository: presetRepository,
            audioPlayer: audioPlayer,
            ticker: ticker,
            tapResetScheduler: tapResetScheduler,
            currentDate: Date.init
        )

        return AppBrain(metronome: metronome)
    }
}
