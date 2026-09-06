import Combine
import UIKit

@MainActor
final class NoteValuePickerViewModel: ObservableObject {
    @Published private(set) var shouldDismiss = false

    let metronome: any MetronomeFeature
    var quickPresets: [QuickPreset] { metronome.quickPresets }

    private var dismissalTask: Task<Void, Never>?
    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
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
