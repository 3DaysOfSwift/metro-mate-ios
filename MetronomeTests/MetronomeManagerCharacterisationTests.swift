import Foundation
import Testing
@testable import Metronome

@Suite(.serialized)
struct MetronomeManagerCharacterisationTests {
    @Test func newManagerUsesTheExistingDefaultBeat() {
        let manager = makeManager()

        #expect(manager.isPlaying == false)
        #expect(manager.bpm == 60)
        #expect(manager.noteValue == .eighth)
        #expect(manager.beatsPerMeasure == 8)
        #expect(manager.gridDisplayMode == .andCounting)
        #expect(manager.currentBeatName == "Eighth")
        #expect(activeIndices(in: manager.gridPattern[0]) == Array(0..<8))
        #expect(activeIndices(in: manager.accentPattern) == [0, 2, 4, 6])
    }

    @Test func changingToSixteenthsRebuildsTheExistingDefaultPattern() {
        let manager = makeManager()

        manager.updateNoteValue(.sixteenth)

        #expect(manager.noteValue == .sixteenth)
        #expect(manager.beatsPerMeasure == 16)
        #expect(manager.gridDisplayMode == .subdivisionCounting)
        #expect(manager.currentBeatName == "Sixteenth")
        #expect(activeIndices(in: manager.gridPattern[0]) == Array(0..<16))
        #expect(activeIndices(in: manager.accentPattern) == [0, 4, 8, 12])
    }

    @Test func changingToEighthTripletsRebuildsTheExistingDefaultPattern() {
        let manager = makeManager()

        manager.updateNoteValue(.eighthTriplet)

        #expect(manager.noteValue == .eighthTriplet)
        #expect(manager.beatsPerMeasure == 6)
        #expect(manager.gridDisplayMode == .andCounting)
        #expect(manager.currentBeatName == "Eighth Triplet")
        #expect(activeIndices(in: manager.gridPattern[0]) == Array(0..<6))
        #expect(activeIndices(in: manager.accentPattern) == [0, 3])
    }

    @Test func editingThePatternMarksItAsCustom() {
        let manager = makeManager()

        manager.toggleGridCell(row: 0, col: 1)

        #expect(manager.gridPattern[0][1] == false)
        #expect(manager.currentBeatName == "Custom Beat")

        manager.toggleAccentCell(col: 1)

        #expect(manager.accentPattern[1])
        #expect(manager.currentBeatName == "Custom Beat")
    }

    @Test func gridBeatLimitsDependOnWhetherThePatternIsATriplet() {
        let manager = makeManager()

        manager.updateNoteValue(.eighthTriplet)
        manager.updateGridBeats(99)
        #expect(manager.beatsPerMeasure == 12)

        manager.updateNoteValue(.eighth)
        manager.updateGridBeats(99)
        #expect(manager.beatsPerMeasure == 16)
    }

    @Test func resetRestoresTheExistingBasicBeat() {
        let manager = makeManager()
        manager.updateNoteValue(.sixteenthTriplet)
        manager.bpm = 147
        manager.toggleGridCell(row: 0, col: 1)

        manager.resetToBasicBeat()

        #expect(manager.bpm == 80)
        #expect(manager.noteValue == .eighth)
        #expect(manager.beatsPerMeasure == 8)
        #expect(manager.gridDisplayMode == .andCounting)
        #expect(manager.currentBeatName == "Eighth")
        #expect(activeIndices(in: manager.gridPattern[0]) == Array(0..<8))
        #expect(activeIndices(in: manager.accentPattern) == [0, 2, 4, 6])
    }

    @Test func randomBeatPreservesTempoAndAlwaysStartsWithAnAccentedBeat() {
        let manager = makeManager()
        manager.bpm = 123

        manager.randomizeBeat()

        #expect(manager.bpm == 123)
        #expect(manager.currentBeatName == "Random Beat")
        #expect(manager.gridPattern[0][0])
        #expect(manager.accentPattern[0])
        #expect(activeIndices(in: manager.gridPattern[0]).count >= 2)
        #expect(activeIndices(in: manager.gridPattern[0]).count <= min(manager.beatsPerMeasure, 12))
    }

    @Test func loadingPresetRestoresAllPersistedConfiguration() {
        let manager = makeManager()
        let preset = BeatPreset(
            name: "Characterisation",
            noteValue: .quarterTriplet,
            bpm: 91,
            beatsPerMeasure: 3,
            gridPattern: [true, false, true],
            accentPattern: [true, false, false],
            gridDisplayMode: .subdivisionCounting
        )

        manager.loadBeatPreset(preset)

        #expect(manager.currentBeatName == "Characterisation")
        #expect(manager.noteValue == .quarterTriplet)
        #expect(manager.bpm == 91)
        #expect(manager.beatsPerMeasure == 3)
        #expect(manager.gridDisplayMode == .subdivisionCounting)
        #expect(Array(manager.gridPattern[0].prefix(3)) == [true, false, true])
        #expect(Array(manager.accentPattern.prefix(3)) == [true, false, false])
    }

    @Test func savingTheSameNameReplacesTheExistingPreset() {
        let manager = makeManager()
        let name = "Characterisation-\(UUID().uuidString)"

        manager.bpm = 80
        manager.saveBeatPreset(name: name)
        manager.bpm = 125
        manager.saveBeatPreset(name: name)

        let matchingPresets = manager.savedBeats.filter { $0.name == name }
        #expect(matchingPresets.count == 1)
        #expect(matchingPresets.first?.bpm == 125)

        if let preset = matchingPresets.first {
            manager.deleteBeatPreset(preset)
        }
    }

    @Test func deletingTheSelectedPresetRestoresTheExistingTitle() {
        let manager = makeManager()
        let name = "Characterisation-\(UUID().uuidString)"
        manager.saveBeatPreset(name: name)
        let preset = manager.savedBeats.first { $0.name == name }

        if let preset {
            manager.deleteBeatPreset(preset)
        }

        #expect(manager.savedBeats.contains { $0.name == name } == false)
        #expect(manager.currentBeatName == "Eighth")
    }

    @Test func savedPresetsAreRestoredByTheNextFeatureInstance() {
        let repository = InMemoryPresetRepository()
        let firstManager = makeManager(repository: repository)

        firstManager.updateBPM(96)
        firstManager.saveBeatPreset(name: "Stored Beat")

        let restoredManager = makeManager(repository: repository)

        #expect(restoredManager.savedBeats.count == 1)
        #expect(restoredManager.savedBeats.first?.name == "Stored Beat")
        #expect(restoredManager.savedBeats.first?.bpm == 96)
    }

    private func activeIndices(in values: [Bool]) -> [Int] {
        values.indices.filter { values[$0] }
    }

    private func makeManager(
        repository: InMemoryPresetRepository = InMemoryPresetRepository()
    ) -> MetronomeManager {
        MetronomeManager(presetRepository: repository)
    }
}
