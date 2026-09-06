import Testing
@testable import Metronome

@MainActor
struct AppBrainTests {
    @Test func failedSaveRetainsChangesForRetryWithoutDuplicatingPresets() {
        enum Failure: Error { case unavailable }
        let repository = InMemoryPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository)
        repository.saveError = Failure.unavailable
        manager.saveBeatPreset(name: "My Beat")
        #expect(manager.presetSaveError != nil)
        #expect(repository.presets.isEmpty)
        #expect(manager.savedBeats.count == 1)
        repository.saveError = nil
        manager.retrySavingPresets()
        #expect(manager.presetSaveError == nil)
        #expect(repository.presets.map(\.name) == ["My Beat"])
    }

    @Test func audioFailureDoesNotStartPlaybackAndCanBeRetried() {
        enum Failure: Error { case unavailable }
        let audio = RecordingMetronomeAudioPlayer()
        let ticker = ControllableMetronomeTicker()
        let manager = makeTestMetronome(audioPlayer: audio, ticker: ticker)
        audio.failure = Failure.unavailable
        manager.prepareAudio()
        #expect(manager.audioError != nil)
        manager.togglePlayback()
        #expect(!manager.isPlaying)
        #expect(ticker.startCallCount == 0)
        audio.failure = nil
        manager.prepareAudio()
        #expect(manager.audioError == nil)
        manager.togglePlayback()
        #expect(manager.isPlaying)
        audio.failure = Failure.unavailable
        manager.tapTempo()
        #expect(!manager.isPlaying)
        #expect(manager.audioError != nil)
    }

    @Test func failedLoadIsVisibleAndRetryCanSucceedWithoutReplacingStoredBeats() {
        enum LoadFailure: Error { case unavailable }
        let repository = InMemoryPresetRepository()
        let original = makeTestMetronome(presetRepository: repository)
        original.saveBeatPreset(name: "Existing")
        repository.loadError = LoadFailure.unavailable
        let manager = makeTestMetronome(presetRepository: repository)
        let viewModel = BeatPresetsViewModel(brain: AppBrain(metronome: manager))

        viewModel.loadSavedPresets()
        #expect(viewModel.loadError != nil)
        manager.saveBeatPreset(name: "Must not overwrite storage")
        #expect(repository.presets.map(\.name) == ["Existing"])

        repository.loadError = nil
        viewModel.loadSavedPresets()
        #expect(viewModel.loadError == nil)
        #expect(manager.savedBeats.map(\.name) == ["Existing"])
    }

    @Test func constructionDoesNotLoadStorageOrPrepareAudio() {
        let repository = InMemoryPresetRepository()
        let audio = RecordingMetronomeAudioPlayer()
        let manager = makeTestMetronome(presetRepository: repository, audioPlayer: audio)
        let brain = AppBrain(metronome: manager)

        #expect(repository.loadCallCount == 0)
        #expect(audio.prepareCallCount == 0)
        brain.applicationDidFinishLaunching()
        #expect(repository.loadCallCount == 1)
        #expect(audio.prepareCallCount == 1)
        brain.applicationDidFinishLaunching()
        #expect(repository.loadCallCount == 1)
    }

    @Test func savingBeforeLaunchLoadsExistingPresetsBeforeAppending() {
        let repository = InMemoryPresetRepository()
        let first = makeTestMetronome(presetRepository: repository)
        first.saveBeatPreset(name: "Existing")
        let second = makeTestMetronome(presetRepository: repository)
        second.saveBeatPreset(name: "New")
        #expect(second.savedBeats.map(\.name) == ["Existing", "New"])
    }

    @Test func storesTheFeatureManagerProvidedByTheCompositionRoot() {
        let metronome = makeTestMetronome()

        let brain = AppBrain(metronome: metronome)

        #expect(brain.metronome === metronome)
    }

    @Test func viewModelsUseTheFeatureFromTheirProvidedBrain() {
        let metronome = makeTestMetronome()
        let brain = AppBrain(metronome: metronome)

        let content = ContentViewModel(brain: brain)
        let settings = SettingsViewModel(brain: brain)

        #expect(content.metronome === metronome)
        #expect(settings.metronome === metronome)
    }
}
