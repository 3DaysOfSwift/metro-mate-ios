import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct BeatPresetsViewModelTests {
    @Test func failedLoadIsVisibleAndRetryCanSucceedWithoutReplacingStoredBeats() async {
        enum LoadFailure: Error { case unavailable }
        let repository = InMemoryPresetRepository()
        let original = makeTestMetronome(presetRepository: repository)
        await original.saveBeatPreset(name: "Existing")
        repository.loadError = LoadFailure.unavailable
        let manager = makeTestMetronome(presetRepository: repository)
        let viewModel = BeatPresetsViewModel(brain: AppBrain(metronome: manager))

        await viewModel.loadSavedPresets()
        #expect(viewModel.loadError != nil)
        await manager.saveBeatPreset(name: "Must not overwrite storage")
        #expect(repository.presets.map(\.name) == ["Existing"])

        repository.loadError = nil
        await viewModel.loadSavedPresets()
        #expect(viewModel.loadError == nil)
        #expect(manager.savedBeats.map(\.name) == ["Existing"])
    }

    @Test func deletingSeveralRowsRemovesTheOriginallySelectedPresets() async {
        let repository = InMemoryPresetRepository()
        let metronome = makeTestMetronome(presetRepository: repository)
        for name in ["First", "Second", "Third", "Fourth"] {
            await metronome.saveBeatPreset(name: name)
        }
        let viewModel = BeatPresetsViewModel(brain: AppBrain(metronome: metronome))

        await viewModel.deleteSavedBeats(at: IndexSet([0, 2]))

        #expect(metronome.savedBeats.map(\.name) == ["Second", "Fourth"])
        #expect(repository.presets.map(\.name) == ["Second", "Fourth"])
        #expect(metronome.currentBeatName == "Fourth")
    }

    @Test func beatPresetsProvidesTheSixExistingDefaults() {
        let viewModel = BeatPresetsViewModel(
            brain: AppBrain(
                metronome: makeTestMetronome()
            )
        )

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
        let metronome = makeTestMetronome()
        let viewModel = BeatPresetsViewModel(brain: AppBrain(metronome: metronome))

        metronome.currentBeatName = "My Beat"
        viewModel.beginSavingCurrentBeat()

        #expect(viewModel.newBeatName == "My Beat")
        #expect(viewModel.isShowingSaveDialog)
    }
}
