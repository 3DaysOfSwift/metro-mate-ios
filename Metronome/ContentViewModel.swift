import Combine
import UIKit

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var isShowingSettings = false
    @Published var isShowingNoteValuePicker = false
    @Published var isShowingGridSettings = false
    @Published var isShowingBeatPresets = false
    @Published var isPlayButtonPressed = false

    let metronome: any MetronomeFeature

    private var repeatTask: Task<Void, Never>?
    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        repeatTask?.cancel()
    }

    func showBeatPresets() {
        lightImpact()
        isShowingBeatPresets = true
    }

    func showSettings() {
        lightImpact()
        isShowingSettings = true
    }

    func showNoteValuePicker() {
        lightImpact()
        isShowingNoteValuePicker = true
    }

    func decreaseBPM() {
        lightImpact()
        metronome.adjustBPM(by: -1)
    }

    func increaseBPM() {
        lightImpact()
        metronome.adjustBPM(by: 1)
    }

    func dragBPM(verticalTranslation: CGFloat) {
        let change = -Double(verticalTranslation) * 0.02
        let newBPM = metronome.adjustedBPM(by: change)

        if Int(newBPM) != Int(metronome.bpm) {
            lightImpact()
        }

        metronome.updateBPM(newBPM)
    }

    func startRepeatingBPMIncrease() {
        startRepeatingBPMChange(by: 1)
    }

    func startRepeatingBPMDecrease() {
        startRepeatingBPMChange(by: -1)
    }

    func stopRepeatingBPMChange() {
        repeatTask?.cancel()
        repeatTask = nil
    }

    func recordTapTempo() {
        mediumImpact()
        metronome.tapTempo()
    }

    func togglePlayback() {
        mediumImpact()
        metronome.togglePlayback()
    }

    func randomizeBeat() {
        lightImpact()
        metronome.randomizeBeat()
    }

    private func startRepeatingBPMChange(by amount: Double) {
        stopRepeatingBPMChange()
        repeatTask = Task { [weak self] in
            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: .milliseconds(100))
                    try Task.checkCancellation()
                    guard let self else { return }
                    self.metronome.adjustBPM(by: amount)
                    self.lightImpact()
                }
            } catch is CancellationError {
                // Releasing the button or replacing the gesture ends repetition.
            } catch {
                return
            }
        }
    }

    private func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func mediumImpact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
