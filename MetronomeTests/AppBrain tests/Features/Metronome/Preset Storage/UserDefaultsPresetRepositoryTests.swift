import Foundation
import Testing
@testable import Metronome

struct UserDefaultsPresetRepositoryTests {
    @MainActor
    @Test func repositoryWorkLeavesTheMainActor() async throws {
        let suite = "MetronomeRepositoryTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsPresetRepository(suiteName: suite, storageKey: "presets")
        try await repository.savePresets([])
        #expect(await repository.executesOffMainThread())
        #expect(try await repository.loadPresets().isEmpty)
        MainActor.assertIsolated()
    }

    @Test func savedFieldsSurviveRepositoryRecreationAndDeletion() async throws {
        let suite = "MetronomeRepositoryTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsPresetRepository(suiteName: suite, storageKey: "presets")
        let preset = BeatPreset(
            name: "Integration", noteValue: .eighth, bpm: 96,
            beatsPerMeasure: 8,
            gridPattern: [true, false, true, false, true, false, true, false],
            accentPattern: [true, false, false, false, true, false, false, false],
            gridDisplayMode: .andCounting
        )
        try await repository.savePresets([preset])
        let reopened = UserDefaultsPresetRepository(
            suiteName: suite, storageKey: "presets"
        )
        let loaded = try #require(try await reopened.loadPresets().first)
        #expect(loaded.id == preset.id)
        #expect(loaded.name == preset.name)
        #expect(loaded.noteValue == preset.noteValue)
        #expect(loaded.bpm == preset.bpm)
        #expect(loaded.beatsPerMeasure == preset.beatsPerMeasure)
        #expect(loaded.gridPattern == preset.gridPattern)
        #expect(loaded.accentPattern == preset.accentPattern)
        #expect(loaded.gridDisplayMode == preset.gridDisplayMode)
        try await reopened.savePresets([])
        #expect(try await repository.loadPresets().isEmpty)
    }

    @Test func corruptDataThrowsAndRemovesOnlyThePresetKey() async throws {
        let suite = "MetronomeRepositoryTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid JSON".utf8), forKey: "presets")
        defaults.set("Retained", forKey: "unrelated")
        let repository = UserDefaultsPresetRepository(suiteName: suite, storageKey: "presets")
        await #expect(throws: DecodingError.self) { try await repository.loadPresets() }
        #expect(defaults.object(forKey: "presets") == nil)
        #expect(defaults.string(forKey: "unrelated") == "Retained")
        #expect(try await repository.loadPresets().isEmpty)
    }
}

private extension UserDefaultsPresetRepository {
    // Runs on the same actor executor as the synchronous storage methods.
    func executesOffMainThread() -> Bool {
        assertIsolated()
        return !Thread.isMainThread
    }
}
