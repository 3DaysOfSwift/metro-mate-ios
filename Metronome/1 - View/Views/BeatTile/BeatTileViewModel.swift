import Observation
import UIKit

@MainActor
@Observable
final class BeatTileViewModel {
    var isPressed = false

    let beat: Int
    private let metronome: any MetronomeFeature

    init(beat: Int, brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        self.beat = beat
        metronome = brain.metronome
    }

    var isActive: Bool {
        beat < metronome.gridPattern[0].count && metronome.gridPattern[0][beat]
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
