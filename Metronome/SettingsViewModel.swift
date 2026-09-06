import Combine
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    let metronome: any MetronomeFeature

    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var beatsPerMeasure: Int {
        get { metronome.beatsPerMeasure }
        set { metronome.updateBeatsPerMeasure(newValue) }
    }

    func finish() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
