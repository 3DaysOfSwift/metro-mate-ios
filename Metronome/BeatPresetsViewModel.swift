import Combine
import UIKit

@MainActor
final class BeatPresetsViewModel: ObservableObject {
    @Published var isShowingSaveDialog = false
    @Published var newBeatName = ""

    let metronome: any MetronomeFeature

    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var defaultPresets: [BeatPreset] { metronome.defaultPresets }

    func beginSavingCurrentBeat() {
        lightImpact()
        newBeatName = metronome.currentBeatName
        isShowingSaveDialog = true
    }

    func saveCurrentBeat() {
        lightImpact()
        guard !newBeatName.isEmpty else { return }
        metronome.saveBeatPreset(name: newBeatName)
    }

    func load(_ preset: BeatPreset) {
        lightImpact()
        metronome.loadBeatPreset(preset)
    }

    func deleteSavedBeats(at offsets: IndexSet) {
        for index in offsets {
            metronome.deleteBeatPreset(metronome.savedBeats[index])
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
