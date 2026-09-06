import Combine
import UIKit

@MainActor
final class NoteValuePickerViewModel: ObservableObject {
    struct QuickPreset: Identifiable {
        let title: String
        let bpm: Int
        let noteValue: NoteValue

        var id: String { title }
    }

    @Published private(set) var shouldDismiss = false

    let metronome: MetronomeManager
    let quickPresets = [
        QuickPreset(title: "Basic", bpm: 120, noteValue: .quarter),
        QuickPreset(title: "Rock", bpm: 110, noteValue: .eighth),
        QuickPreset(title: "Jazz", bpm: 140, noteValue: .quarterTriplet),
        QuickPreset(title: "Fast", bpm: 160, noteValue: .sixteenth)
    ]

    private var dismissalTask: Task<Void, Never>?
    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain = .shared) {
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
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
        metronome.bpm = Double(preset.bpm)
        metronome.updateBPM(Double(preset.bpm))
        metronome.updateNoteValue(preset.noteValue)
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
