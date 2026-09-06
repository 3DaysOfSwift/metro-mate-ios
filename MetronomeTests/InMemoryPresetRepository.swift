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

func makeTestMetronome(
    presetRepository: InMemoryPresetRepository = InMemoryPresetRepository(),
    audioPlayer: RecordingMetronomeAudioPlayer = RecordingMetronomeAudioPlayer()
) -> MetronomeManager {
    MetronomeManager(
        presetRepository: presetRepository,
        audioPlayer: audioPlayer
    )
}
