import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct SettingsViewModelTests {
    @Test func settingsUpdatesTheBeatCountThroughTheExistingFeature() {
        let metronome = makeTestMetronome()
        let viewModel = SettingsViewModel(brain: AppBrain(metronome: metronome))

        viewModel.beatsPerMeasure = 5

        #expect(metronome.beatsPerMeasure == 5)
        #expect(metronome.gridPattern[0].count == 16)
    }
}
