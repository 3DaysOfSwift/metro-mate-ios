import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct AppBrainTests {
    @Test func constructionDoesNotLoadStorageOrPrepareAudio() async {
        let repository = InMemoryPresetRepository()
        let audio = RecordingMetronomeAudioPlayer()
        let manager = makeTestMetronome(presetRepository: repository, audioPlayer: audio)
        let brain = AppBrain(metronome: manager)

        #expect(repository.loadCallCount == 0)
        #expect(audio.prepareCallCount == 0)
        await brain.applicationDidFinishLaunching()
        #expect(repository.loadCallCount == 1)
        #expect(audio.prepareCallCount == 1)
        await brain.applicationDidFinishLaunching()
        #expect(repository.loadCallCount == 1)
    }

    @Test func storesTheFeatureManagerProvidedByTheCompositionRoot() {
        let metronome = makeTestMetronome()

        let brain = AppBrain(metronome: metronome)

        #expect(brain.metronome === metronome)
    }
}
