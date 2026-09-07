import Foundation
import Observation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct MetronomePresetPersistenceTests {
    @Test(.timeLimit(.minutes(1)))
    func sameNameEditsWaitingForInitialLoadKeepSubmissionOrder() async {
        let repository = SuspendedPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository)
        manager.updateBPM(80)
        let first = Task { await manager.saveBeatPreset(name: "Beat") }
        await repository.waitForLoad()
        manager.updateBPM(120)
        let entered = AsyncStream<Void>.makeStream()
        let second = Task {
            entered.continuation.yield()
            await manager.saveBeatPreset(name: "Beat")
        }
        var arrivals = entered.stream.makeAsyncIterator()
        await arrivals.next()
        let changed = AsyncStream<Void>.makeStream()
        // The second command is submitted before the shared load is released.
        repository.finishLoad()
        await repository.waitForSave()
        if manager.savedBeats.first?.bpm != 120 {
            withObservationTracking { _ = manager.savedBeats } onChange: {
                changed.continuation.yield()
            }
            var events = changed.stream.makeAsyncIterator()
            await events.next()
        }
        #expect(manager.savedBeats.first?.bpm == 120)
        let firstWriteHasLatest = repository.writes.last?.first?.bpm == 120
        repository.finishSave()
        if !firstWriteHasLatest {
            await repository.waitForSave()
            #expect(repository.writes.last?.first?.bpm == 120)
            repository.finishSave()
        }
        await first.value
        await second.value
        #expect(manager.savedBeats.count == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func slowStorageCoalescesSnapshotsWithoutLosingEdits() async {
        let repository = SuspendedPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository)
        let first = Task { await manager.saveBeatPreset(name: "First") }
        await repository.waitForLoad()
        repository.finishLoad()
        await repository.waitForSave()
        var pending: [Task<Void, Never>] = []
        for name in ["Second", "Third"] {
            let changed = AsyncStream<Void>.makeStream()
            withObservationTracking { _ = manager.currentBeatName } onChange: {
                changed.continuation.yield()
            }
            pending.append(Task { await manager.saveBeatPreset(name: name) })
            var events = changed.stream.makeAsyncIterator()
            await events.next()
        }
        #expect(repository.writes.count == 1)
        first.cancel()
        repository.finishSave()
        await repository.waitForSave()
        #expect(repository.writes.last?.map(\.name) == ["First", "Second", "Third"])
        repository.finishSave()
        await first.value
        for task in pending { await task.value }
        #expect(repository.writes.count == 2)
        #expect(!manager.isSavingPresets)
    }

    @Test(.timeLimit(.minutes(1)))
    func concurrentCallersShareOnePendingLoad() async {
        let repository = SuspendedPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository)
        let first = Task { await manager.loadSavedPresets() }
        await repository.waitForLoad()
        #expect(manager.isLoadingPresets)
        let started = AsyncStream<Void>.makeStream()
        let second = Task {
            started.continuation.yield()
            await manager.loadSavedPresets()
        }
        var events = started.stream.makeAsyncIterator()
        await events.next()
        #expect(repository.loadCallCount == 1)
        repository.finishLoad()
        await first.value
        await second.value
        #expect(!manager.isLoadingPresets)
        #expect(repository.loadCallCount == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func saveCapturesTheBeatBeforeLoadingSuspends() async {
        let repository = SuspendedPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository)
        manager.updateBPM(96)
        let save = Task { await manager.saveBeatPreset(name: "Original") }
        await repository.waitForLoad()
        manager.updateBPM(140)
        repository.finishLoad()
        await repository.waitForSave()
        #expect(repository.writes.first?.first?.bpm == 96)
        #expect(manager.isSavingPresets)
        repository.finishSave()
        await save.value
        #expect(!manager.isSavingPresets)
    }

    @Test(.timeLimit(.minutes(1)))
    func overlappingSavesPreserveOrderAndIgnoreAnOlderFailure() async {
        enum Failure: Error { case unavailable }
        let repository = SuspendedPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository)
        let first = Task { await manager.saveBeatPreset(name: "First") }
        await repository.waitForLoad()
        repository.finishLoad()
        await repository.waitForSave()
        let changed = AsyncStream<Void>.makeStream()
        withObservationTracking {
            _ = manager.savedBeats
        } onChange: {
            changed.continuation.yield()
        }
        let second = Task { await manager.saveBeatPreset(name: "Second") }
        var events = changed.stream.makeAsyncIterator()
        await events.next()
        #expect(manager.savedBeats.count == 2)
        #expect(repository.writes.count == 1)
        // Cancelling the initiating screen must not discard a committed write.
        first.cancel()
        repository.finishSave(error: Failure.unavailable)
        await repository.waitForSave()
        #expect(repository.writes.map { $0.map(\.name) } == [["First"], ["First", "Second"]])
        #expect(manager.presetSaveError == nil)
        #expect(manager.isSavingPresets)
        repository.finishSave()
        await first.value
        await second.value
        #expect(!manager.isSavingPresets)
        #expect(manager.presetSaveError == nil)
    }

    @Test func failedSaveRetainsChangesForRetryWithoutDuplicatingPresets() async {
        enum Failure: Error { case unavailable }
        let repository = InMemoryPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository)
        repository.saveError = Failure.unavailable
        await manager.saveBeatPreset(name: "My Beat")
        #expect(manager.presetSaveError != nil)
        #expect(repository.presets.isEmpty)
        #expect(manager.savedBeats.count == 1)
        repository.saveError = nil
        await manager.retrySavingPresets()
        #expect(manager.presetSaveError == nil)
        #expect(repository.presets.map(\.name) == ["My Beat"])
    }

    @Test func savingBeforeLaunchLoadsExistingPresetsBeforeAppending() async {
        let repository = InMemoryPresetRepository()
        let first = makeTestMetronome(presetRepository: repository)
        await first.saveBeatPreset(name: "Existing")
        let second = makeTestMetronome(presetRepository: repository)
        await second.saveBeatPreset(name: "New")
        #expect(second.savedBeats.map(\.name) == ["Existing", "New"])
    }
}
