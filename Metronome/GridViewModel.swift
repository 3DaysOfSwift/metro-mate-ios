import Combine
import UIKit

@MainActor
final class GridViewModel: ObservableObject {
    let metronome: MetronomeManager

    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain = .shared) {
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var numberOfRows: Int {
        (metronome.beatsPerMeasure + tilesPerRow - 1) / tilesPerRow
    }

    var tilesPerRow: Int {
        metronome.noteValue.isTriplet ? 3 : 4
    }

    func tilesInRow(_ row: Int) -> Int {
        let remainingBeats = metronome.beatsPerMeasure - (row * tilesPerRow)
        return min(tilesPerRow, remainingBeats)
    }

    func isAccentActive(at beat: Int) -> Bool {
        beat < metronome.accentPattern.count && metronome.accentPattern[beat]
    }

    func isCurrentAccent(at beat: Int) -> Bool {
        isAccentActive(at: beat) && beat == metronome.currentBeat && metronome.isPlaying
    }

    func toggleAccent(at beat: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        metronome.toggleAccentCell(col: beat)
    }
}
