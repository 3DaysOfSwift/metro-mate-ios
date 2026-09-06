import Foundation
import Combine
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct SharedFeatureObservationTests {
    @Test func featureChangesNotifyBothScreenViewModelsWithoutCopyingState() {
        let manager = makeTestMetronome()
        let brain = AppBrain(metronome: manager)
        let content = ContentViewModel(brain: brain)
        let presets = BeatPresetsViewModel(brain: brain)
        var contentNotifications = 0
        var presetNotifications = 0
        let contentSubscription = content.objectWillChange.sink { contentNotifications += 1 }
        let presetSubscription = presets.objectWillChange.sink { presetNotifications += 1 }

        manager.updateBPM(96)

        #expect(contentNotifications > 0)
        #expect(presetNotifications > 0)
        // objectWillChange precedes mutation; read the computed values after the command.
        #expect(content.bpm == 96)
        #expect(presets.bpm == 96)
        #expect(content.minimumBPM == Int(manager.tempoRange.lowerBound))
        #expect(content.maximumBPM == Int(manager.tempoRange.upperBound))
        withExtendedLifetime((contentSubscription, presetSubscription)) {}
    }

    @Test func viewModelsUseTheFeatureFromTheirProvidedBrain() {
        let metronome = makeTestMetronome()
        let brain = AppBrain(metronome: metronome)

        let content = ContentViewModel(brain: brain)
        let settings = SettingsViewModel(brain: brain)

        metronome.updateBPM(96)
        #expect(content.bpm == 96)
        settings.beatsPerMeasure = 6
        #expect(metronome.beatsPerMeasure == 6)
        #expect(settings.beatsPerMeasure == 6)
    }
}
