import Foundation
import CoreGraphics
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct StarFieldViewModelTests {
    @Test func frameCalculationHasAnOffMainOwner() async throws {
        let renderer = StarFieldRenderer()
        #expect(await renderer.executesOffMainThread())
        let frame = try await renderer.render(size: CGSize(width: 100, height: 80), bpm: 60,
                                              wavePhase: 0, pulseTime: 1, intensity: 1)
        #expect(frame.count == 14)
        #expect(frame.allSatisfy { $0.count == 16 })
    }

    @Test func resizePublishesOnlyTheNewCanvasShape() async throws {
        let viewModel = StarFieldViewModel(metronome: makeTestMetronome())
        viewModel.appear(in: CGSize(width: 430, height: 932))
        viewModel.resize(to: CGSize(width: 100, height: 80))
        defer { viewModel.disappear() }
        try await waitForFrame(viewModel)
        #expect(viewModel.dots.count == 14)
        #expect(viewModel.dots.allSatisfy { $0.count == 16 })
    }

    @Test(.timeLimit(.minutes(1)))
    func fullScreenAnimationPublishesANewFrameWithoutChangingTheOldSnapshot() async throws {
        let viewModel = StarFieldViewModel(metronome: makeTestMetronome())
        viewModel.appear(in: CGSize(width: 430, height: 932))
        defer { viewModel.disappear() }
        try await waitForFrame(viewModel)
        let clock = ContinuousClock()
        let snapshot = viewModel.dots
        let originalLastX = snapshot.last!.last!.x
        let deadline = clock.now.advanced(by: .seconds(3))
        while viewModel.dots.last!.last!.x == originalLastX && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(viewModel.dots.last!.last!.x != originalLastX)
        #expect(snapshot.last!.last!.x == originalLastX)
        #expect(viewModel.dots.count == snapshot.count)
    }

    @Test func starFieldBuildsDotsForItsCanvasAndCanStopAnimating() async throws {
        let viewModel = StarFieldViewModel(
            metronome: makeTestMetronome()
        )

        viewModel.appear(in: CGSize(width: 100, height: 80))
        try await waitForFrame(viewModel)

        #expect(viewModel.dots.count == 14)
        #expect(viewModel.dots.allSatisfy { $0.count == 16 })

        viewModel.disappear()
    }

    @Test func starFieldStopsUpdatingWhenHiddenAndResumesOnAppearance() async throws {
        let viewModel = StarFieldViewModel(metronome: makeTestMetronome())
        let size = CGSize(width: 100, height: 80)
        defer { viewModel.disappear() }

        for _ in 0..<2 {
            viewModel.appear(in: size)
            try await waitForFrame(viewModel)
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
            metronome: makeTestMetronome()
        )
        weak var releasedViewModel = viewModel
        viewModel?.appear(in: CGSize(width: 100, height: 80))
        try await Task.sleep(for: .milliseconds(50))
        viewModel = nil
        #expect(releasedViewModel == nil)
    }

    private func waitForFrame(_ viewModel: StarFieldViewModel) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(3))
        while viewModel.dots.isEmpty && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(!viewModel.dots.isEmpty)
    }
}

private extension StarFieldRenderer {
    func executesOffMainThread() -> Bool {
        assertIsolated()
        return !Thread.isMainThread
    }
}
