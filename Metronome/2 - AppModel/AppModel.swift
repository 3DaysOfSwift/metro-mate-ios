import Foundation

@MainActor
final class AppModel {
    static let shared = AppModel.live()

    let metronome: any MetronomeFeature

    init(metronome: any MetronomeFeature) {
        self.metronome = metronome
    }

    /// An early opportunity to warm audio and load saved presets before interaction.
    /// Features own readiness; playback does not depend on this callback running first.
    func applicationDidFinishLaunching() async {
        async let audio: Void = metronome.prepareAudio()
        async let presets: Void = metronome.loadSavedPresets()
        _ = await (audio, presets)
    }

    /// Produces the live, non-test AppModel and constructs all production dependencies in one place.
    static func live() -> AppModel {
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

        return AppModel(metronome: metronome)
    }
}
