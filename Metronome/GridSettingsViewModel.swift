import Combine
import UIKit

@MainActor
final class GridSettingsViewModel: ObservableObject {
    let metronome: MetronomeManager

    private var metronomeUpdates: AnyCancellable?

    init(metronome: MetronomeManager = .shared) {
        self.metronome = metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var beatsPerMeasure: Int { metronome.beatsPerMeasure }
    var maximumBeatCount: Int { metronome.noteValue.isTriplet ? 12 : 16 }

    func updateBeatCount(_ count: Double) {
        metronome.updateGridBeats(Int(count))
    }

    func finish() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
