import Observation
import UIKit

@MainActor
@Observable
final class GridViewModel {
    private let metronome: any MetronomeFeature

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        metronome = brain.metronome
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
