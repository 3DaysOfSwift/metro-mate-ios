import Observation
import UIKit

@MainActor
@Observable
final class GridSettingsViewModel {
    private let metronome: any MetronomeFeature

    init(metronome: (any MetronomeFeature)? = nil) {
        self.metronome = metronome ?? AppModel.shared.metronome
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
