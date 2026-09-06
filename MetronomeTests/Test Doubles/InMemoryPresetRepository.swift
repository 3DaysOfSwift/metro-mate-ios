import Foundation

@testable import Metronome

final class InMemoryPresetRepository: PresetRepository {
    private(set) var presets: [BeatPreset]
    private(set) var loadCallCount = 0
    var loadError: Error?

    init(presets: [BeatPreset] = []) {
        self.presets = presets
    }

    func loadPresets() throws -> [BeatPreset] {
        loadCallCount += 1
        if let loadError { throw loadError }
        return presets
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
    tapResetScheduler: ControllableDelayScheduler? = nil,
    blinkScheduler: ControllableDelayScheduler? = nil,
    currentDate: @escaping () -> Date = Date.init
) -> MetronomeManager {
    MetronomeManager(
        presetRepository: presetRepository,
        audioPlayer: audioPlayer,
        ticker: ticker ?? ControllableMetronomeTicker(),
        tapResetScheduler: tapResetScheduler ?? ControllableDelayScheduler(),
        blinkScheduler: blinkScheduler ?? ControllableDelayScheduler(),
        currentDate: currentDate
    )
}
