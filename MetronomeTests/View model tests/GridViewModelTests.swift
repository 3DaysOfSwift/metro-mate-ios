import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct GridViewModelTests {
    @Test func gridLayoutUsesFourColumnsForOrdinaryNotes() {
        let metronome = makeTestMetronome()
        let viewModel = GridViewModel(metronome: metronome)

        #expect(viewModel.tilesPerRow == 4)
        #expect(viewModel.numberOfRows == 2)
        #expect(viewModel.tilesInRow(0) == 4)
        #expect(viewModel.tilesInRow(1) == 4)
    }

    @Test func gridLayoutUsesThreeColumnsForTriplets() {
        let metronome = makeTestMetronome()
        metronome.updateNoteValue(.eighthTriplet)
        let viewModel = GridViewModel(metronome: metronome)

        #expect(viewModel.tilesPerRow == 3)
        #expect(viewModel.numberOfRows == 2)
        #expect(viewModel.tilesInRow(0) == 3)
        #expect(viewModel.tilesInRow(1) == 3)
    }
}
