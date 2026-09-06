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

    /// Called on the audio executor. Mix rather than queue overlapping click tails.
    func render(normal: [[Float]], accented: [[Float]], sampleRate: Double, firstBeat: Int) throws -> [[Float]] {
        let frames = try framesPerBeat(sampleRate: sampleRate)
        guard normal.count == 2, accented.count == 2, beats.indices.contains(firstBeat) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let length = frames * beats.count
        var output = Array(repeating: Array(repeating: Float.zero, count: length), count: 2)
        for offset in beats.indices {
            guard let accent = beats[(firstBeat + offset) % beats.count] else { continue }
            let click = accent ? accented : normal
            for channel in 0..<2 {
                for frame in click[channel].indices {
                    output[channel][(offset * frames + frame) % length] += click[channel][frame]
                }
            }
        }
        for channel in 0..<2 {
            for frame in 0..<length { output[channel][frame] = min(1, max(-1, output[channel][frame])) }
        }
        return output
    }
}
