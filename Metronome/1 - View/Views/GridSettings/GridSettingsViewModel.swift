import Combine
import UIKit

@MainActor
final class GridSettingsViewModel: ObservableObject {
    private let metronome: any MetronomeFeature

    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var beatsPerMeasure: Int { metronome.beatsPerMeasure }
    var minimumBeatCount: Int { metronome.gridBeatCountRange.lowerBound }
    var maximumBeatCount: Int { metronome.gridBeatCountRange.upperBound }
    var sliderRange: ClosedRange<Double> {
        Double(minimumBeatCount)...Double(maximumBeatCount)
    }

    func updateBeatCount(_ count: Double) {
        metronome.updateGridBeats(Int(count))
    }

    func finish() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
