import Observation
import UIKit

@MainActor
@Observable
final class BeatTileViewModel {
    var isPressed = false

    let beat: Int
    private let metronome: any MetronomeFeature

    init(beat: Int, metronome: (any MetronomeFeature)? = nil) {
        self.beat = beat
        self.metronome = metronome ?? AppBrain.shared.metronome
    }

    var isActive: Bool {
        metronome.isBeatActive(beat)
    }

    var isCurrent: Bool {
        beat == metronome.currentBeat && metronome.isPlaying
    }

    var label: String {
        metronome.gridDisplayMode.getLabel(for: beat, noteValue: metronome.noteValue)
    }

    func toggleBeat() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        metronome.toggleGridCell(row: 0, col: beat)
    }
}
