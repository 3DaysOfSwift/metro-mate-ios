import Observation
import UIKit

@MainActor
@Observable
final class NoteValuePickerViewModel {
    private(set) var shouldDismiss = false

    private let metronome: any MetronomeFeature
    var noteValue: NoteValue { metronome.noteValue }
    var quickPresets: [QuickPreset] { metronome.quickPresets }

    /// Decorative dots summarise the pattern; they are not the actual beat count.
    func visualBeatCount(for noteValue: NoteValue) -> Int {
        switch noteValue {
        case .quarter: return 4
        case .eighth, .sixteenth: return 8
        case .quarterTriplet: return 3
        case .eighthTriplet, .sixteenthTriplet: return 6
        }
    }

    @ObservationIgnored private var dismissalTask: Task<Void, Never>?

    init(metronome: (any MetronomeFeature)? = nil) {
        self.metronome = metronome ?? AppModel.shared.metronome
    }

    deinit {
        dismissalTask?.cancel()
    }

    func select(_ noteValue: NoteValue) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        metronome.updateNoteValue(noteValue)
        requestDismissalAfterSelection()
    }

    func select(_ preset: QuickPreset) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        metronome.applyQuickPreset(preset)
        requestDismissalAfterSelection()
    }

    private func requestDismissalAfterSelection() {
        dismissalTask?.cancel()
        dismissalTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            self?.shouldDismiss = true
        }
    }
}
