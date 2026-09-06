import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct BeatTileViewModelTests {
    @Test func beatTileReadsAndUpdatesItsOwnBeat() {
        let metronome = makeTestMetronome()
        let viewModel = BeatTileViewModel(beat: 1, metronome: metronome)

        #expect(viewModel.isActive)
        #expect(viewModel.label == "&")

        viewModel.toggleBeat()

        #expect(viewModel.isActive == false)
        #expect(metronome.currentBeatName == "Custom Beat")
    }
}
