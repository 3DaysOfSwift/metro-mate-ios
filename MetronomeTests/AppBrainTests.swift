import Testing
@testable import Metronome

@MainActor
struct AppBrainTests {
    @Test func storesTheFeatureManagerProvidedByTheCompositionRoot() {
        let metronome = MetronomeManager(presetRepository: InMemoryPresetRepository())

        let brain = AppBrain(metronome: metronome)

        #expect(brain.metronome === metronome)
    }

    @Test func viewModelsUseTheFeatureFromTheirProvidedBrain() {
        let metronome = MetronomeManager(presetRepository: InMemoryPresetRepository())
        let brain = AppBrain(metronome: metronome)

        let content = ContentViewModel(brain: brain)
        let settings = SettingsViewModel(brain: brain)

        #expect(content.metronome === metronome)
        #expect(settings.metronome === metronome)
    }
}
