import Combine
import UIKit

@MainActor
final class BeatTileViewModel: ObservableObject {
    @Published var isPressed = false

    let beat: Int
    let metronome: MetronomeManager

    private var metronomeUpdates: AnyCancellable?

    init(beat: Int, metronome: MetronomeManager = .shared) {
        self.beat = beat
        self.metronome = metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
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
