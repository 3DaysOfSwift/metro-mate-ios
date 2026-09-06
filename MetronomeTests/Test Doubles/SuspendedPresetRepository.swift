import Foundation
@testable import Metronome

/// Pauses storage at its actual await boundaries; tests decide when work finishes.
@MainActor
final class SuspendedPresetRepository: PresetRepository {
    private let loadEvents = AsyncStream<Void>.makeStream()
    private let saveEvents = AsyncStream<Void>.makeStream()
    private var pendingLoad: CheckedContinuation<[BeatPreset], any Error>?
    private var pendingSave: CheckedContinuation<Void, any Error>?
    private(set) var loadCallCount = 0
    private(set) var writes: [[BeatPreset]] = []

    func loadPresets() async throws -> [BeatPreset] {
        loadCallCount += 1
        return try await withCheckedThrowingContinuation {
            pendingLoad = $0
            loadEvents.continuation.yield()
        }
    }

    func savePresets(_ presets: [BeatPreset]) async throws {
        writes.append(presets)
        try await withCheckedThrowingContinuation {
            pendingSave = $0
            saveEvents.continuation.yield()
        }
    }

    func waitForLoad() async {
        var events = loadEvents.stream.makeAsyncIterator()
        await events.next()
    }

    func waitForSave() async {
        var events = saveEvents.stream.makeAsyncIterator()
        await events.next()
    }

    func finishLoad(with presets: [BeatPreset] = []) {
        let continuation = pendingLoad
        pendingLoad = nil
        continuation?.resume(returning: presets)
    }

    func finishSave(error: (any Error)? = nil) {
        let continuation = pendingSave
        pendingSave = nil
        if let error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }
    }
}
