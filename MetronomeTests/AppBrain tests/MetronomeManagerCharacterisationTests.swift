import Foundation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct MetronomeManagerCharacterisationTests {
    @Test func repeatedPlaybackRequestsKeepPlayingWithoutRestartingTheTicker() throws {
        let ticker = ControllableMetronomeTicker()
        let audio = RecordingMetronomeAudioPlayer()
        let manager = makeManager(audioPlayer: audio, ticker: ticker)

        try manager.startPlayback()
        try manager.startPlayback()

        #expect(manager.isPlaying)
        #expect(audio.startCallCount == 1)
        #expect(ticker.startCallCount == 1)
        manager.togglePlayback()
    }

    @Test func playbackAtRequestedTempoWorksBeforeLaunchAndRetimesWhenAlreadyPlaying() throws {
        let ticker = ControllableMetronomeTicker()
        let manager = makeManager(ticker: ticker)

        try manager.startPlayback(atBPM: 120)
        #expect(manager.isPlaying)
        #expect(manager.bpm == 120)
        #expect(ticker.interval == .milliseconds(250))
        #expect(ticker.startCallCount == 1)

        try manager.startPlayback(atBPM: 60)
        #expect(manager.isPlaying)
        #expect(manager.bpm == 60)
        #expect(ticker.interval == .milliseconds(500))
        #expect(ticker.startCallCount == 2)
        manager.togglePlayback()
    }

    @Test func playbackRequestReportsAudioFailureAndCanBeRetried() throws {
        enum Failure: Error { case unavailable }
        let audio = RecordingMetronomeAudioPlayer()
        let ticker = ControllableMetronomeTicker()
        let manager = makeManager(audioPlayer: audio, ticker: ticker)
        audio.failure = Failure.unavailable

        #expect(throws: (any Error).self) {
            try manager.startPlayback(atBPM: 120)
        }
        #expect(!manager.isPlaying)
        #expect(manager.audioError != nil)
        #expect(ticker.startCallCount == 0)

        audio.failure = nil
        try manager.startPlayback()
        #expect(manager.isPlaying)
        #expect(manager.audioError == nil)
        #expect(manager.bpm == 120)
        manager.togglePlayback()
    }

    @Test func savingAnEmptyPresetNameLeavesStateAndStorageUnchanged() {
        let repository = InMemoryPresetRepository()
        let manager = makeManager(repository: repository)
        manager.saveBeatPreset(name: "Saved Beat")
        let savedIDs = manager.savedBeats.map(\.id)

        manager.saveBeatPreset(name: "")

        #expect(manager.savedBeats.map(\.id) == savedIDs)
        #expect(repository.presets.map(\.id) == savedIDs)
        #expect(manager.currentBeatName == "Saved Beat")
    }

    @Test func availableBeatRangesPreserveTheSettingsAndGridDistinction() {
        let manager = makeManager()
        for note in NoteValue.allCases {
            manager.updateNoteValue(note)
            #expect(manager.beatCountRange == 1...16)
            #expect(manager.gridBeatCountRange == 1...(note.isTriplet ? 12 : 16))
            manager.updateGridBeats(99)
            #expect(manager.beatsPerMeasure == manager.gridBeatCountRange.upperBound)
        }
    }

    @Test func tempoAdjustmentsRespectLimitsAndPreserveFractionalValues() {
        let manager = makeManager()
        #expect(manager.adjustedBPM(by: 0.5) == 60.5)
        #expect(manager.bpm == 60)

        manager.adjustBPM(by: 0.5)
        #expect(manager.bpm == 60.5)
        manager.adjustBPM(by: -1_000)
        #expect(manager.bpm == 40)
        manager.adjustBPM(by: 1_000)
        #expect(manager.bpm == 200)
    }

    @Test func adjustingTempoWhilePlayingUpdatesPlaybackTiming() {
        let ticker = ControllableMetronomeTicker()
        let manager = makeManager(ticker: ticker)
        manager.togglePlayback()
        manager.adjustBPM(by: 60)
        #expect(manager.bpm == 120)
        #expect(ticker.interval == .milliseconds(250))
        #expect(ticker.startCallCount == 2)
    }

    @Test func quickPresetsRetainTheirExistingMusicalSettings() {
        let manager = makeManager()
        #expect(manager.quickPresets.map(\.title) == ["Basic", "Rock", "Jazz", "Fast"])
        #expect(manager.quickPresets.map(\.bpm) == [120, 110, 140, 160])
        #expect(manager.quickPresets.map(\.noteValue) == [.quarter, .eighth, .quarterTriplet, .sixteenth])

        for preset in manager.quickPresets {
            manager.applyQuickPreset(preset)
            #expect(manager.bpm == Double(preset.bpm))
            #expect(manager.noteValue == preset.noteValue)
            #expect(manager.beatsPerMeasure == preset.noteValue.beatsPerMeasure)
            #expect(activeIndices(in: manager.gridPattern[0]) == Array(0..<manager.beatsPerMeasure))
        }
    }

    @Test func builtInPresetsRetainTheirTempoPatternsAndCountingModes() {
        let manager = makeManager()
        let presets = manager.defaultPresets
        #expect(presets.map(\.name) == [
            "Quarter", "Eighth", "Sixteenth", "Quarter Triplet", "Eighth Triplet", "Sixteenth Triplet"
        ])
        #expect(presets.map(\.beatsPerMeasure) == [4, 8, 16, 3, 6, 12])
        #expect(presets.allSatisfy { $0.bpm == 80 })
        let expectedAccents = [[0, 1, 2, 3], [0, 2, 4, 6], [0, 4, 8, 12], [0, 1, 2], [0, 3], [0, 3, 6, 9]]
        for (preset, accents) in zip(presets, expectedAccents) {
            #expect(preset.gridPattern.count == 16)
            #expect(preset.accentPattern.count == 16)
            #expect(activeIndices(in: preset.gridPattern) == Array(0..<preset.beatsPerMeasure))
            #expect(activeIndices(in: preset.accentPattern) == accents)
        }
        #expect(presets.map(\.gridDisplayMode) == [
            .andCounting, .andCounting, .subdivisionCounting,
            .andCounting, .andCounting, .subdivisionCounting
        ])
        // Browsing presets must not apply one to the active metronome.
        #expect(manager.bpm == 60)
        #expect(manager.noteValue == .eighth)
    }

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
        restoredManager.loadSavedPresets()

        #expect(restoredManager.savedBeats.count == 1)
        #expect(restoredManager.savedBeats.first?.name == "Stored Beat")
        #expect(restoredManager.savedBeats.first?.bpm == 96)
    }

    @Test func playbackCommandsAreForwardedToTheSuppliedAudioPlayer() {
        let audioPlayer = RecordingMetronomeAudioPlayer()
        let manager = makeManager(audioPlayer: audioPlayer)

        #expect(audioPlayer.prepareCallCount == 0)

        manager.togglePlayback()
        #expect(audioPlayer.startCallCount == 1)

        manager.togglePlayback()
        #expect(audioPlayer.stopCallCount == 1)

        manager.tapTempo()
        #expect(audioPlayer.playedAccents == [false])
    }

    @Test func playbackUsesAControllableTickerWithoutWaitingForRealTime() {
        let audioPlayer = RecordingMetronomeAudioPlayer()
        let ticker = ControllableMetronomeTicker()
        let manager = makeManager(audioPlayer: audioPlayer, ticker: ticker)

        manager.togglePlayback()

        #expect(ticker.initialDelay == .milliseconds(10))
        #expect(ticker.interval == .milliseconds(500))
        #expect(manager.currentBeat == -1)

        ticker.sendTick()

        #expect(manager.currentBeat == 0)
        #expect(audioPlayer.playedAccents == [true])
    }

    @Test func tapTempoUsesTheAverageOfRecentTapIntervals() {
        var now = Date(timeIntervalSince1970: 1_000)
        let manager = makeManager(currentDate: { now })

        manager.tapTempo()
        now = now.addingTimeInterval(0.5)
        manager.tapTempo()
        now = now.addingTimeInterval(1.0)
        manager.tapTempo()

        #expect(manager.bpm == 80)
    }

    @Test func tapTempoClampsAnUnreasonablyFastTempo() {
        var now = Date(timeIntervalSince1970: 1_000)
        let manager = makeManager(currentDate: { now })

        manager.tapTempo()
        now = now.addingTimeInterval(0.1)
        manager.tapTempo()

        #expect(manager.bpm == 200)
    }

    @Test func tapTempoIgnoresTapsOlderThanThreeSeconds() {
        var now = Date(timeIntervalSince1970: 1_000)
        let manager = makeManager(currentDate: { now })

        manager.tapTempo()
        now = now.addingTimeInterval(4)
        manager.tapTempo()

        #expect(manager.tapTimes == [now])
        #expect(manager.bpm == 60)
    }

    @Test func tapCountResetsThreeSecondsAfterTheMostRecentTap() {
        let tapResetScheduler = ControllableDelayScheduler()
        let manager = makeManager(tapResetScheduler: tapResetScheduler)

        manager.tapTempo()
        manager.tapTempo()

        #expect(manager.tapCount == 2)
        #expect(tapResetScheduler.delays == [.seconds(3)])
        #expect(tapResetScheduler.cancelCallCount == 2)

        tapResetScheduler.completeAllDelays()

        #expect(manager.tapCount == 0)
    }

    @Test func tappingTriggersTheExistingBriefVisualPulse() {
        let blinkScheduler = ControllableDelayScheduler()
        let manager = makeManager(blinkScheduler: blinkScheduler)

        manager.tapTempo()

        #expect(manager.shouldBlink)
        #expect(blinkScheduler.delays == [.milliseconds(100)])

        blinkScheduler.completeAllDelays()

        #expect(manager.shouldBlink == false)
    }

    @Test func changingTempoReplacesTheRunningTicker() {
        let ticker = ControllableMetronomeTicker()
        let manager = makeManager(ticker: ticker)
        manager.togglePlayback()

        manager.updateBPM(120)

        #expect(ticker.startCallCount == 2)
        #expect(ticker.initialDelay == .milliseconds(250))
        #expect(ticker.interval == .milliseconds(250))
    }

    private func activeIndices(in values: [Bool]) -> [Int] {
        values.indices.filter { values[$0] }
    }

    private func makeManager(
        repository: InMemoryPresetRepository = InMemoryPresetRepository(),
        audioPlayer: RecordingMetronomeAudioPlayer = RecordingMetronomeAudioPlayer(),
        ticker: ControllableMetronomeTicker? = nil,
        tapResetScheduler: ControllableDelayScheduler? = nil,
        blinkScheduler: ControllableDelayScheduler? = nil,
        currentDate: @escaping () -> Date = Date.init
    ) -> MetronomeManager {
        MetronomeManager(
            presetRepository: repository,
            audioPlayer: audioPlayer,
            ticker: ticker ?? ControllableMetronomeTicker(),
            tapResetScheduler: tapResetScheduler ?? ControllableDelayScheduler(),
            blinkScheduler: blinkScheduler ?? ControllableDelayScheduler(),
            currentDate: currentDate
        )
    }
}
