import Observation
import UIKit

@MainActor
@Observable
final class ContentViewModel {
    var isShowingSettings = false
    var isShowingNoteValuePicker = false
    var isShowingGridSettings = false
    var isShowingBeatPresets = false
    var isPlayButtonPressed = false

    private let metronome: any MetronomeFeature
    var currentBeatName: String { metronome.currentBeatName }
    var bpm: Double { metronome.bpm }
    var noteValue: NoteValue { metronome.noteValue }
    var tapCount: Int { metronome.tapCount }
    var isPlaying: Bool { metronome.isPlaying }
    var isStartingPlayback: Bool { metronome.isStartingPlayback }
    var shouldBlink: Bool { metronome.shouldBlink }
    var minimumBPM: Int { Int(metronome.tempoRange.lowerBound) }
    var maximumBPM: Int { Int(metronome.tempoRange.upperBound) }
    var audioError: String? { metronome.audioError }

    func retryAudio() async {
        await metronome.prepareAudio()
    }

    @ObservationIgnored private var repeatTask: Task<Void, Never>?

    init(metronome: (any MetronomeFeature)? = nil) {
        self.metronome = metronome ?? AppModel.shared.metronome
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

    func recordTapTempo() async {
        mediumImpact()
        await metronome.tapTempo()
    }

    func togglePlayback() async {
        mediumImpact()
        await metronome.togglePlayback()
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
