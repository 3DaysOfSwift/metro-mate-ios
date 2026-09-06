import Foundation

@MainActor
final class AppBrain {
    static let shared = AppBrain.live()

    let metronome: any MetronomeFeature

    init(metronome: any MetronomeFeature) {
        self.metronome = metronome
    }

    /// An early opportunity to warm audio and load saved presets before interaction.
    /// Features own readiness; playback does not depend on this callback running first.
    func applicationDidFinishLaunching() async {
        metronome.prepareAudio()
        await metronome.loadSavedPresets()
    }

    /// Produces the live, non-test AppBrain and constructs all production dependencies in one place.
    static func live() -> AppBrain {
        let presetRepository = UserDefaultsPresetRepository(
            suiteName: nil,
            storageKey: "savedBeatPresets"
        )
        let audioPlayer = AVFoundationMetronomeAudioPlayer(bundle: .main)
        let ticker = SwiftConcurrencyMetronomeTicker()
        let tapResetScheduler = SwiftConcurrencyDelayScheduler()
        let blinkScheduler = SwiftConcurrencyDelayScheduler()
        let metronome = MetronomeManager(
            presetRepository: presetRepository,
            audioPlayer: audioPlayer,
            ticker: ticker,
            tapResetScheduler: tapResetScheduler,
            blinkScheduler: blinkScheduler,
            currentDate: Date.init
        )

        return AppBrain(metronome: metronome)
    }
}
