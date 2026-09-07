import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct AppModelTests {
    @Test func constructionDoesNotLoadStorageOrPrepareAudio() async {
        let repository = InMemoryPresetRepository()
        let audio = RecordingMetronomeAudioPlayer()
        let manager = makeTestMetronome(presetRepository: repository, audioPlayer: audio)
        let appModel = AppModel(metronome: manager)

        #expect(repository.loadCallCount == 0)
        #expect(audio.prepareCallCount == 0)
        await appModel.applicationDidFinishLaunching()
        #expect(repository.loadCallCount == 1)
        #expect(audio.prepareCallCount == 1)
        await appModel.applicationDidFinishLaunching()
        #expect(repository.loadCallCount == 1)
    }

    @Test func storesTheFeatureManagerProvidedByTheCompositionRoot() {
        let metronome = makeTestMetronome()

        let appModel = AppModel(metronome: metronome)

        #expect(appModel.metronome === metronome)
    }
}
