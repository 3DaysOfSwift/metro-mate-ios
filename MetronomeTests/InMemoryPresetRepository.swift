@testable import Metronome

final class InMemoryPresetRepository: PresetRepository {
    private(set) var presets: [BeatPreset]

    init(presets: [BeatPreset] = []) {
        self.presets = presets
    }

    func loadPresets() throws -> [BeatPreset] {
        presets
    }

    func savePresets(_ presets: [BeatPreset]) throws {
        self.presets = presets
    }
}

@MainActor
func makeTestMetronome(
    presetRepository: InMemoryPresetRepository = InMemoryPresetRepository(),
    audioPlayer: RecordingMetronomeAudioPlayer = RecordingMetronomeAudioPlayer(),
    ticker: ControllableMetronomeTicker? = nil,
    currentDate: @escaping () -> Date = Date.init
) -> MetronomeManager {
    MetronomeManager(
        presetRepository: presetRepository,
        audioPlayer: audioPlayer,
        ticker: ticker ?? ControllableMetronomeTicker(),
        currentDate: currentDate
    )
}
