import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct NoteValuePickerViewModelTests {
    @Test func notePickerRetainsItsDecorativeDotCounts() {
        let viewModel = NoteValuePickerViewModel(brain: AppBrain(metronome: makeTestMetronome()))
        #expect(viewModel.visualBeatCount(for: .quarter) == 4)
        #expect(viewModel.visualBeatCount(for: .eighth) == 8)
        #expect(viewModel.visualBeatCount(for: .sixteenth) == 8)
        #expect(viewModel.visualBeatCount(for: .quarterTriplet) == 3)
        #expect(viewModel.visualBeatCount(for: .eighthTriplet) == 6)
        #expect(viewModel.visualBeatCount(for: .sixteenthTriplet) == 6)
    }

    @Test func noteValueSelectionUpdatesTheMetronomeBeforeDismissal() {
        let metronome = makeTestMetronome()
        let viewModel = NoteValuePickerViewModel(brain: AppBrain(metronome: metronome))

        viewModel.select(.sixteenth)

        #expect(metronome.noteValue == .sixteenth)
        #expect(viewModel.shouldDismiss == false)
    }

    @Test func quickPresetSelectionUpdatesTempoAndNoteValue() {
        let metronome = makeTestMetronome()
        let viewModel = NoteValuePickerViewModel(brain: AppBrain(metronome: metronome))
        let jazz = viewModel.quickPresets.first { $0.title == "Jazz" }

        if let jazz {
            viewModel.select(jazz)
        }

        #expect(metronome.bpm == 140)
        #expect(metronome.noteValue == .quarterTriplet)
    }
}
