import Foundation
import CoreGraphics
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct StarFieldViewModelTests {
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
