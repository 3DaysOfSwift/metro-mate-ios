import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct MetronomePresetPersistenceTests {
    @Test func failedSaveRetainsChangesForRetryWithoutDuplicatingPresets() {
        enum Failure: Error { case unavailable }
        let repository = InMemoryPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository)
        repository.saveError = Failure.unavailable
        manager.saveBeatPreset(name: "My Beat")
        #expect(manager.presetSaveError != nil)
        #expect(repository.presets.isEmpty)
        #expect(manager.savedBeats.count == 1)
        repository.saveError = nil
        manager.retrySavingPresets()
        #expect(manager.presetSaveError == nil)
        #expect(repository.presets.map(\.name) == ["My Beat"])
    }

    @Test func savingBeforeLaunchLoadsExistingPresetsBeforeAppending() {
        let repository = InMemoryPresetRepository()
        let first = makeTestMetronome(presetRepository: repository)
        first.saveBeatPreset(name: "Existing")
        let second = makeTestMetronome(presetRepository: repository)
        second.saveBeatPreset(name: "New")
        #expect(second.savedBeats.map(\.name) == ["Existing", "New"])
    }
}
