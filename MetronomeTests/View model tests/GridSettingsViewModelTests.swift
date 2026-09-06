import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct GridSettingsViewModelTests {
    @Test func gridSettingsDescribesAndUpdatesItsCurrentRange() {
        let metronome = makeTestMetronome()
        let viewModel = GridSettingsViewModel(brain: AppBrain(metronome: metronome))

        #expect(viewModel.maximumBeatCount == 16)
        viewModel.updateBeatCount(7)
        #expect(viewModel.beatsPerMeasure == 7)

        metronome.updateNoteValue(.eighthTriplet)
        #expect(viewModel.maximumBeatCount == 12)
    }
}
