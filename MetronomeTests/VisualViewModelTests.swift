import CoreGraphics
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct VisualViewModelTests {
    @Test func gridLayoutUsesFourColumnsForOrdinaryNotes() {
        let metronome = MetronomeManager(presetRepository: InMemoryPresetRepository())
        let viewModel = GridViewModel(brain: AppBrain(metronome: metronome))

        #expect(viewModel.tilesPerRow == 4)
        #expect(viewModel.numberOfRows == 2)
        #expect(viewModel.tilesInRow(0) == 4)
        #expect(viewModel.tilesInRow(1) == 4)
    }

    @Test func gridLayoutUsesThreeColumnsForTriplets() {
        let metronome = MetronomeManager(presetRepository: InMemoryPresetRepository())
        metronome.updateNoteValue(.eighthTriplet)
        let viewModel = GridViewModel(brain: AppBrain(metronome: metronome))

        #expect(viewModel.tilesPerRow == 3)
        #expect(viewModel.numberOfRows == 2)
        #expect(viewModel.tilesInRow(0) == 3)
        #expect(viewModel.tilesInRow(1) == 3)
    }

    @Test func beatTileReadsAndUpdatesItsOwnBeat() {
        let metronome = MetronomeManager(presetRepository: InMemoryPresetRepository())
        let viewModel = BeatTileViewModel(beat: 1, brain: AppBrain(metronome: metronome))

        #expect(viewModel.isActive)
        #expect(viewModel.label == "&")

        viewModel.toggleBeat()

        #expect(viewModel.isActive == false)
        #expect(metronome.currentBeatName == "Custom Beat")
    }

    @Test func starFieldBuildsDotsForItsCanvasAndCanStopAnimating() {
        let viewModel = StarFieldViewModel(
            brain: AppBrain(
                metronome: MetronomeManager(presetRepository: InMemoryPresetRepository())
            )
        )

        viewModel.appear(in: CGSize(width: 100, height: 80))

        #expect(viewModel.dots.count == 14)
        #expect(viewModel.dots.allSatisfy { $0.count == 16 })

        viewModel.disappear()
    }
}
