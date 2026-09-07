import Foundation

/// Fixed-capacity reservation policy for AVAudioPlayerNodes sharing one sample
/// timeline. Reusing a voice is permitted only after its previous click ends.
struct MetronomeVoicePool: Sendable {
    private var availableAt: [Int64]
    var capacity: Int { availableAt.count }

    init(capacity: Int) throws {
        guard (1...64).contains(capacity) else { throw CocoaError(.validationMissingMandatoryProperty) }
        availableAt = Array(repeating: 0, count: capacity)
    }

    mutating func reserve(at sample: Int64, frameCount: Int64) throws -> Int {
        guard sample >= 0, frameCount > 0, sample <= Int64.max - frameCount else {
            throw CocoaError(.validationMissingMandatoryProperty)
        }
        guard let voice = availableAt.firstIndex(where: { $0 <= sample }) else {
            // The caller must report capacity exhaustion, never silently cut a tail.
            throw CocoaError(.coderInvalidValue)
        }
        availableAt[voice] = sample + frameCount
        return voice
    }

    mutating func reset() {
        availableAt = Array(repeating: 0, count: capacity)
    }
}
