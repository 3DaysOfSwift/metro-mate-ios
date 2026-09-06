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

    private var repeatTimer: Timer?
    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        repeatTimer?.invalidate()
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
        changeBPM(by: -1)
    }

    func increaseBPM() {
        lightImpact()
        changeBPM(by: 1)
    }

    func dragBPM(verticalTranslation: CGFloat) {
        let change = -Double(verticalTranslation) * 0.02
        let newBPM = max(40, min(200, metronome.bpm + change))

        if Int(newBPM) != Int(metronome.bpm) {
            lightImpact()
        }

        setBPM(newBPM)
    }

    func startRepeatingBPMIncrease() {
        startRepeatingBPMChange(by: 1)
    }

    func startRepeatingBPMDecrease() {
        startRepeatingBPMChange(by: -1)
    }

    func stopRepeatingBPMChange() {
        repeatTimer?.invalidate()
        repeatTimer = nil
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
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.changeBPM(by: amount)
                self?.lightImpact()
            }
        }
    }

    private func changeBPM(by amount: Double) {
        setBPM(max(40, min(200, metronome.bpm + amount)))
    }

    private func setBPM(_ bpm: Double) {
        metronome.updateBPM(bpm)
    }

    private func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func mediumImpact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
