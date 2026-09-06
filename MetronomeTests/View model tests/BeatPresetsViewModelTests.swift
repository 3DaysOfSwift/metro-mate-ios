import Foundation
import Testing
import Observation
import Synchronization
@testable import Metronome

@MainActor
@Suite(.serialized)
struct BeatPresetsViewModelTests {
    @Test func screenObservesLoadFailureAndSuccessfulRetry() async {
        enum Failure: Error { case unavailable }
        let repository = InMemoryPresetRepository()
        repository.loadError = Failure.unavailable
        let manager = makeTestMetronome(presetRepository: repository)
        let viewModel = BeatPresetsViewModel(metronome: manager)
        let loadingChanges = Mutex(0)
        let errorChanges = Mutex(0)
        withObservationTracking {
            _ = viewModel.isLoading
        } onChange: {
            loadingChanges.withLock { $0 += 1 }
        }
        withObservationTracking {
            _ = viewModel.loadError
        } onChange: {
            errorChanges.withLock { $0 += 1 }
        }
        await viewModel.loadSavedPresets()
        #expect(loadingChanges.withLock { $0 } == 1)
        #expect(errorChanges.withLock { $0 } == 1)
        #expect(viewModel.loadError != nil)
        #expect(!viewModel.isLoading)
        withObservationTracking {
            _ = viewModel.loadError
        } onChange: {
            errorChanges.withLock { $0 += 1 }
        }
        repository.loadError = nil
        await viewModel.loadSavedPresets()
        #expect(errorChanges.withLock { $0 } == 2)
        #expect(viewModel.loadError == nil)
    }

    @Test func saveDialogBindingsUpdateOnlyLocalPresentationState() {
        let manager = makeTestMetronome()
        let viewModel = BeatPresetsViewModel(metronome: manager)
        let notifications = Mutex(0)
        withObservationTracking {
            _ = viewModel.newBeatName
        } onChange: {
            notifications.withLock { $0 += 1 }
        }
        viewModel.newBeatName = "Draft"
        #expect(notifications.withLock { $0 } == 1)
        #expect(viewModel.newBeatName == "Draft")
        #expect(manager.savedBeats.isEmpty)
    }

    @Test func failedLoadIsVisibleAndRetryCanSucceedWithoutReplacingStoredBeats() async {
        enum LoadFailure: Error { case unavailable }
        let repository = InMemoryPresetRepository()
        let original = makeTestMetronome(presetRepository: repository)
        await original.saveBeatPreset(name: "Existing")
        repository.loadError = LoadFailure.unavailable
        let manager = makeTestMetronome(presetRepository: repository)
        let viewModel = BeatPresetsViewModel(metronome: manager)

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
        let viewModel = BeatPresetsViewModel(metronome: metronome)

        await viewModel.deleteSavedBeats(at: IndexSet([0, 2]))

        #expect(metronome.savedBeats.map(\.name) == ["Second", "Fourth"])
        #expect(repository.presets.map(\.name) == ["Second", "Fourth"])
        #expect(metronome.currentBeatName == "Fourth")
    }

    @Test func beatPresetsProvidesTheSixExistingDefaults() {
        let viewModel = BeatPresetsViewModel(
            metronome: makeTestMetronome()
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

    @Test func beginningToSaveCopiesTheCurrentBeatName() async {
        let metronome = makeTestMetronome()
        let viewModel = BeatPresetsViewModel(metronome: metronome)

        await metronome.saveBeatPreset(name: "My Beat")
        viewModel.beginSavingCurrentBeat()

        #expect(viewModel.newBeatName == "My Beat")
        #expect(viewModel.isShowingSaveDialog)
    }
}
