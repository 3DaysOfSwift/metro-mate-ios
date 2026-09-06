import Combine
import UIKit

@MainActor
final class BeatPresetsViewModel: ObservableObject {
    @Published var isShowingSaveDialog = false
    @Published var newBeatName = ""

    let metronome: any MetronomeFeature

    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain = .shared) {
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var defaultPresets: [BeatPreset] {
        let presets: [(NoteValue, String)] = [
            (.quarter, "Quarter"),
            (.eighth, "Eighth"),
            (.sixteenth, "Sixteenth"),
            (.quarterTriplet, "Quarter Triplet"),
            (.eighthTriplet, "Eighth Triplet"),
            (.sixteenthTriplet, "Sixteenth Triplet")
        ]

        return presets.map(makeDefaultPreset)
    }

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

    private func makeDefaultPreset(noteValue: NoteValue, name: String) -> BeatPreset {
        let beatsPerMeasure = noteValue.beatsPerMeasure
        var gridPattern = Array(repeating: false, count: 16)
        var accentPattern = Array(repeating: false, count: 16)

        for index in 0..<beatsPerMeasure {
            gridPattern[index] = true
        }

        let accentPositions: [Int]
        switch noteValue {
        case .quarter:
            accentPositions = Array(0..<min(4, beatsPerMeasure))
        case .eighth:
            accentPositions = [0, 2, 4, 6]
        case .sixteenth:
            accentPositions = [0, 4, 8, 12]
        case .quarterTriplet:
            accentPositions = Array(0..<min(3, beatsPerMeasure))
        case .eighthTriplet:
            accentPositions = [0, 3]
        case .sixteenthTriplet:
            accentPositions = [0, 3, 6, 9]
        }

        for position in accentPositions where position < beatsPerMeasure {
            accentPattern[position] = true
        }

        let displayMode: GridDisplayMode = switch noteValue {
        case .sixteenth, .sixteenthTriplet: .subdivisionCounting
        default: .andCounting
        }

        return BeatPreset(
            name: name,
            noteValue: noteValue,
            bpm: 80,
            beatsPerMeasure: beatsPerMeasure,
            gridPattern: gridPattern,
            accentPattern: accentPattern,
            gridDisplayMode: displayMode
        )
    }

    private func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
