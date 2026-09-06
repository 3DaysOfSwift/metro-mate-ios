import Observation
import UIKit

@MainActor
@Observable
final class SettingsViewModel {
    private let metronome: any MetronomeFeature

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        metronome = brain.metronome
    }

    var beatsPerMeasure: Int {
        get { metronome.beatsPerMeasure }
        set { metronome.updateBeatsPerMeasure(newValue) }
    }

    var beatCountRange: ClosedRange<Int> { metronome.beatCountRange }

    func finish() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
