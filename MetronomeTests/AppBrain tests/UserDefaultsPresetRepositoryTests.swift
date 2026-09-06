import Foundation
import Testing
@testable import Metronome

struct UserDefaultsPresetRepositoryTests {
    @Test func savedFieldsSurviveRepositoryRecreationAndDeletion() throws {
        let suite = "MetronomeRepositoryTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsPresetRepository(userDefaults: defaults, storageKey: "presets")
        let preset = BeatPreset(
            name: "Integration", noteValue: .eighth, bpm: 96,
            beatsPerMeasure: 8,
            gridPattern: [true, false, true, false, true, false, true, false],
            accentPattern: [true, false, false, false, true, false, false, false],
            gridDisplayMode: .andCounting
        )
        try repository.savePresets([preset])
        let reopened = UserDefaultsPresetRepository(
            userDefaults: try #require(UserDefaults(suiteName: suite)), storageKey: "presets"
        )
        let loaded = try #require(try reopened.loadPresets().first)
        #expect(loaded.id == preset.id)
        #expect(loaded.name == preset.name)
        #expect(loaded.noteValue == preset.noteValue)
        #expect(loaded.bpm == preset.bpm)
        #expect(loaded.beatsPerMeasure == preset.beatsPerMeasure)
        #expect(loaded.gridPattern == preset.gridPattern)
        #expect(loaded.accentPattern == preset.accentPattern)
        #expect(loaded.gridDisplayMode == preset.gridDisplayMode)
        try reopened.savePresets([])
        #expect(try repository.loadPresets().isEmpty)
    }

    @Test func corruptDataThrowsAndRemovesOnlyThePresetKey() throws {
        let suite = "MetronomeRepositoryTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid JSON".utf8), forKey: "presets")
        defaults.set("Retained", forKey: "unrelated")
        let repository = UserDefaultsPresetRepository(userDefaults: defaults, storageKey: "presets")
        #expect(throws: DecodingError.self) { try repository.loadPresets() }
        #expect(defaults.object(forKey: "presets") == nil)
        #expect(defaults.string(forKey: "unrelated") == "Retained")
        #expect(try repository.loadPresets().isEmpty)
    }
}
