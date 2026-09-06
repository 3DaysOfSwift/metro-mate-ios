import Observation
import UIKit

@MainActor
@Observable
final class BeatPresetsViewModel {
    var isShowingSaveDialog = false
    var newBeatName = ""

    private let metronome: any MetronomeFeature
    var currentBeatName: String { metronome.currentBeatName }
    var noteValue: NoteValue { metronome.noteValue }
    var bpm: Double { metronome.bpm }
    var beatsPerMeasure: Int { metronome.beatsPerMeasure }
    var savedBeats: [BeatPreset] { metronome.savedBeats }

    init(metronome: (any MetronomeFeature)? = nil) {
        self.metronome = metronome ?? AppBrain.shared.metronome
    }

    var defaultPresets: [BeatPreset] { metronome.defaultPresets }
    var loadError: String? { metronome.presetLoadError }
    var saveError: String? { metronome.presetSaveError }

    var isLoading: Bool { metronome.isLoadingPresets }
    var isSaving: Bool { metronome.isSavingPresets }

    func retrySavingPresets() async {
        await metronome.retrySavingPresets()
    }

    func loadSavedPresets() async {
        await metronome.loadSavedPresets()
    }

    func beginSavingCurrentBeat() {
        lightImpact()
        newBeatName = metronome.currentBeatName
        isShowingSaveDialog = true
    }

    func saveCurrentBeat() async {
        lightImpact()
        await metronome.saveBeatPreset(name: newBeatName)
    }

    func load(_ preset: BeatPreset) {
        lightImpact()
        metronome.loadBeatPreset(preset)
    }

    func deleteSavedBeats(at offsets: IndexSet) async {
        let selectedPresets = offsets.map { metronome.savedBeats[$0] }
        for preset in selectedPresets {
            await metronome.deleteBeatPreset(preset)
        }
    }

    func reset() {
        lightImpact()
        metronome.resetToBasicBeat()
    }

    func finish() {
        lightImpact()
    }

    private func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
