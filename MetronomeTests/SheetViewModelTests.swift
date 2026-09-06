import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct SheetViewModelTests {
    @Test func settingsUpdatesTheBeatCountThroughTheExistingFeature() {
        let metronome = MetronomeManager()
        let viewModel = SettingsViewModel(metronome: metronome)

        viewModel.beatsPerMeasure = 5

        #expect(metronome.beatsPerMeasure == 5)
        #expect(metronome.gridPattern[0].count == 16)
    }

    @Test func gridSettingsDescribesAndUpdatesItsCurrentRange() {
        let metronome = MetronomeManager()
        let viewModel = GridSettingsViewModel(metronome: metronome)

        #expect(viewModel.maximumBeatCount == 16)
        viewModel.updateBeatCount(7)
        #expect(viewModel.beatsPerMeasure == 7)

        metronome.updateNoteValue(.eighthTriplet)
        #expect(viewModel.maximumBeatCount == 12)
    }

    @Test func beatPresetsProvidesTheSixExistingDefaults() {
        let viewModel = BeatPresetsViewModel(metronome: MetronomeManager())

        #expect(viewModel.defaultPresets.map(\.name) == [
            "Quarter",
            "Eighth",
            "Sixteenth",
            "Quarter Triplet",
            "Eighth Triplet",
            "Sixteenth Triplet"
        ])
        #expect(viewModel.defaultPresets.map(\.beatsPerMeasure) == [4, 8, 16, 3, 6, 12])
    }

    @Test func beginningToSaveCopiesTheCurrentBeatName() {
        let metronome = MetronomeManager()
        let viewModel = BeatPresetsViewModel(metronome: metronome)

        metronome.currentBeatName = "My Beat"
        viewModel.beginSavingCurrentBeat()

        #expect(viewModel.newBeatName == "My Beat")
        #expect(viewModel.isShowingSaveDialog)
    }

    @Test func noteValueSelectionUpdatesTheMetronomeBeforeDismissal() {
        let metronome = MetronomeManager()
        let viewModel = NoteValuePickerViewModel(metronome: metronome)

        viewModel.select(.sixteenth)

        #expect(metronome.noteValue == .sixteenth)
        #expect(viewModel.shouldDismiss == false)
    }

    @Test func quickPresetSelectionUpdatesTempoAndNoteValue() {
        let metronome = MetronomeManager()
        let viewModel = NoteValuePickerViewModel(metronome: metronome)
        let jazz = viewModel.quickPresets.first { $0.title == "Jazz" }

        if let jazz {
            viewModel.select(jazz)
        }

        #expect(metronome.bpm == 140)
        #expect(metronome.noteValue == .quarterTriplet)
    }
}
