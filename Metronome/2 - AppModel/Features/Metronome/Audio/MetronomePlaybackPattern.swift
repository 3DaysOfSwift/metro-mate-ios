import Foundation

/// A value snapshot of the musical instructions, not a sequence of UI callbacks.
struct MetronomePlaybackPattern: Sendable, Equatable {
    let interval: Double
    let beats: [Bool?] // nil is silent; true is accented.
    let restartFromFirstBeat: Bool

    func framesPerBeat(sampleRate: Double) throws -> Int {
        guard sampleRate.isFinite, sampleRate > 0, sampleRate <= 192_000,
              interval.isFinite, interval >= 0.01, interval <= 10,
              !beats.isEmpty, beats.count <= 64 else {
            throw CocoaError(.validationMissingMandatoryProperty)
        }
        return max(1, Int((interval * sampleRate).rounded()))
    }

}
