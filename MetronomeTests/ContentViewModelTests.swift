import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct ContentViewModelTests {
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
