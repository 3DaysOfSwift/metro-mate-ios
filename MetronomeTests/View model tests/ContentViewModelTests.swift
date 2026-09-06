import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct ContentViewModelTests {
    @Test(arguments: [true, false])
    func holdingTempoButtonRepeatsUntilReleased(increasing: Bool) async throws {
        let metronome = makeTestMetronome()
        let viewModel = ContentViewModel(brain: AppBrain(metronome: metronome))
        defer { viewModel.stopRepeatingBPMChange() }

        if increasing {
            viewModel.startRepeatingBPMIncrease()
        } else {
            viewModel.startRepeatingBPMDecrease()
        }
        #expect(metronome.bpm == 60)

        // Exercise the real Task runtime, allowing for a busy test host.
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(3))
        while metronome.bpm == 60 && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(increasing ? metronome.bpm > 60 : metronome.bpm < 60)

        viewModel.stopRepeatingBPMChange()
        let releasedBPM = metronome.bpm
        try await Task.sleep(for: .milliseconds(250))
        #expect(metronome.bpm == releasedBPM)
    }

    @Test func releasingViewModelCancelsTheHeldButtonTask() async throws {
        let metronome = makeTestMetronome()
        var viewModel: ContentViewModel? = ContentViewModel(brain: AppBrain(metronome: metronome))
        weak var releasedViewModel = viewModel
        viewModel?.startRepeatingBPMIncrease()
        await Task.yield()
        viewModel = nil

        #expect(releasedViewModel == nil)
        let releasedBPM = metronome.bpm
        try await Task.sleep(for: .milliseconds(250))
        #expect(metronome.bpm == releasedBPM)
    }

    @Test func presentationIntentsExposeTheRequestedSheet() {
        let viewModel = ContentViewModel(
            brain: AppBrain(
                metronome: makeTestMetronome()
            )
        )

        viewModel.showBeatPresets()
        viewModel.showSettings()
        viewModel.showNoteValuePicker()

        #expect(viewModel.isShowingBeatPresets)
        #expect(viewModel.isShowingSettings)
        #expect(viewModel.isShowingNoteValuePicker)
    }

    @Test func bpmButtonsRespectTheExistingLimits() {
        let metronome = makeTestMetronome()
        let viewModel = ContentViewModel(brain: AppBrain(metronome: metronome))

        metronome.bpm = 40
        viewModel.decreaseBPM()
        #expect(metronome.bpm == 40)

        metronome.bpm = 200
        viewModel.increaseBPM()
        #expect(metronome.bpm == 200)
    }

    @Test func bpmDragUsesTheExistingSensitivityAndLimits() {
        let metronome = makeTestMetronome()
        let viewModel = ContentViewModel(brain: AppBrain(metronome: metronome))

        metronome.bpm = 100
        viewModel.dragBPM(verticalTranslation: -50)
        #expect(metronome.bpm == 101)

        viewModel.dragBPM(verticalTranslation: -10_000)
        #expect(metronome.bpm == 200)
    }
}
