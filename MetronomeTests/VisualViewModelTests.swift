import CoreGraphics
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct VisualViewModelTests {
    @Test func gridLayoutUsesFourColumnsForOrdinaryNotes() {
        let metronome = makeTestMetronome()
        let viewModel = GridViewModel(brain: AppBrain(metronome: metronome))

        #expect(viewModel.tilesPerRow == 4)
        #expect(viewModel.numberOfRows == 2)
        #expect(viewModel.tilesInRow(0) == 4)
        #expect(viewModel.tilesInRow(1) == 4)
    }

    @Test func gridLayoutUsesThreeColumnsForTriplets() {
        let metronome = makeTestMetronome()
        metronome.updateNoteValue(.eighthTriplet)
        let viewModel = GridViewModel(brain: AppBrain(metronome: metronome))

        #expect(viewModel.tilesPerRow == 3)
        #expect(viewModel.numberOfRows == 2)
        #expect(viewModel.tilesInRow(0) == 3)
        #expect(viewModel.tilesInRow(1) == 3)
    }

    @Test func beatTileReadsAndUpdatesItsOwnBeat() {
        let metronome = makeTestMetronome()
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
                metronome: makeTestMetronome()
            )
        )

        viewModel.appear(in: CGSize(width: 100, height: 80))

        #expect(viewModel.dots.count == 14)
        #expect(viewModel.dots.allSatisfy { $0.count == 16 })

        viewModel.disappear()
    }

    @Test func starFieldStopsUpdatingWhenHiddenAndResumesOnAppearance() async throws {
        let viewModel = StarFieldViewModel(brain: AppBrain(metronome: makeTestMetronome()))
        let size = CGSize(width: 100, height: 80)
        defer { viewModel.disappear() }

        for _ in 0..<2 {
            viewModel.appear(in: size)
            let initialX = viewModel.dots[0][0].x
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: .seconds(3))
            while viewModel.dots[0][0].x == initialX && clock.now < deadline {
                try await Task.sleep(for: .milliseconds(10))
            }
            #expect(viewModel.dots[0][0].x != initialX)

            viewModel.disappear()
            let stoppedX = viewModel.dots[0][0].x
            try await Task.sleep(for: .milliseconds(100))
            #expect(viewModel.dots[0][0].x == stoppedX)
        }
    }

    @Test func animationDoesNotKeepItsViewModelAlive() async throws {
        var viewModel: StarFieldViewModel? = StarFieldViewModel(
            brain: AppBrain(metronome: makeTestMetronome())
        )
        weak var releasedViewModel = viewModel
        viewModel?.appear(in: CGSize(width: 100, height: 80))
        try await Task.sleep(for: .milliseconds(50))
        viewModel = nil
        #expect(releasedViewModel == nil)
    }
}
