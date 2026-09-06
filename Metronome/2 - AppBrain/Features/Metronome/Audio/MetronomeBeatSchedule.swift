import Foundation

/// Candidate scheduling policy. It does not own a timer, player, or UI state.
/// The audio owner commits only a bounded look-ahead window with commit(until:).
struct MetronomeBeatSchedule: Sendable {
    struct Beat: Sendable, Equatable {
        let sampleTime: Int64
        let index: Int
        let accented: Bool?
    }

    private let sampleRate: Double
    private var pattern: MetronomePlaybackPattern
    private var pendingPattern: MetronomePlaybackPattern?
    private var nextSample: Double
    private var nextBeat = 0

    init(pattern: MetronomePlaybackPattern, sampleRate: Double, startSample: Int64 = 0) throws {
        _ = try pattern.framesPerBeat(sampleRate: sampleRate)
        guard startSample >= 0 else { throw CocoaError(.validationMissingMandatoryProperty) }
        self.pattern = pattern
        self.sampleRate = sampleRate
        self.nextSample = Double(startSample)
    }

    mutating func update(_ pattern: MetronomePlaybackPattern) throws {
        _ = try pattern.framesPerBeat(sampleRate: sampleRate)
        // Replace the pending request, never postpone the existing deadline.
        pendingPattern = pattern
    }

    /// Commits events before an exclusive sample boundary. Silent beats still
    /// appear in the timeline so presentation can follow the musical position.
    mutating func commit(until endSample: Int64) -> [Beat] {
        var result: [Beat] = []
        while nextSample.rounded() < Double(endSample) {
            if let pendingPattern {
                pattern = pendingPattern
                self.pendingPattern = nil
                nextBeat = pattern.restartFromFirstBeat ? 0 : nextBeat % pattern.beats.count
            }
            result.append(Beat(sampleTime: Int64(nextSample.rounded()),
                               index: nextBeat, accented: pattern.beats[nextBeat]))
            // Accumulate fractional frames, rounding only the absolute deadline.
            // Rounding each individual interval would accumulate tempo drift.
            nextSample += pattern.interval * sampleRate
            nextBeat = (nextBeat + 1) % pattern.beats.count
        }
        return result
    }
}
