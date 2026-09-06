import Foundation
import Observation
import Synchronization
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct SharedFeatureObservationTests {
    @Test func trackingIgnoresUnrelatedChangesAndCanBeRegisteredAgain() {
        let manager = makeTestMetronome()
        let content = ContentViewModel(metronome: manager)
        let notifications = Mutex(0)
        for tempo in [96.0, 110.0] {
            withObservationTracking {
                _ = content.bpm
            } onChange: {
                notifications.withLock { $0 += 1 }
            }
            let before = notifications.withLock { $0 }
            manager.toggleBeat(at: 0)
            #expect(notifications.withLock { $0 } == before)
            manager.updateBPM(tempo)
            #expect(notifications.withLock { $0 } == before + 1)
            #expect(content.bpm == tempo)
        }
    }

    @Test func collectionMutationInvalidatesDerivedTileState() {
        let manager = makeTestMetronome()
        let tile = BeatTileViewModel(beat: 0, metronome: manager)
        let original = tile.isActive
        let notifications = Mutex(0)
        withObservationTracking {
            _ = tile.isActive
        } onChange: {
            notifications.withLock { $0 += 1 }
        }
        manager.toggleBeat(at: 0)
        #expect(notifications.withLock { $0 } == 1)
        #expect(tile.isActive != original)
    }

    @Test func featureChangesNotifyBothScreenViewModelsWithoutCopyingState() {
        let manager = makeTestMetronome()
        let brain = AppBrain(metronome: manager)
        let content = ContentViewModel(metronome: brain.metronome)
        let presets = BeatPresetsViewModel(metronome: brain.metronome)
        let contentNotifications = Mutex(0)
        let presetNotifications = Mutex(0)
        withObservationTracking {
            _ = content.bpm
        } onChange: {
            contentNotifications.withLock { $0 += 1 }
        }
        withObservationTracking {
            _ = presets.bpm
        } onChange: {
            presetNotifications.withLock { $0 += 1 }
        }

        manager.updateBPM(96)

        #expect(contentNotifications.withLock { $0 } == 1)
        #expect(presetNotifications.withLock { $0 } == 1)
        // Observation notifies before mutation; read values after the command.
        #expect(content.bpm == 96)
        #expect(presets.bpm == 96)
        #expect(content.minimumBPM == Int(manager.tempoRange.lowerBound))
        #expect(content.maximumBPM == Int(manager.tempoRange.upperBound))
    }

    @Test func viewModelsUseTheFeatureFromTheirProvidedBrain() {
        let metronome = makeTestMetronome()
        let brain = AppBrain(metronome: metronome)

        let content = ContentViewModel(metronome: brain.metronome)
        let settings = SettingsViewModel(metronome: brain.metronome)

        metronome.updateBPM(96)
        #expect(content.bpm == 96)
        settings.beatsPerMeasure = 6
        #expect(metronome.beatsPerMeasure == 6)
        #expect(settings.beatsPerMeasure == 6)
    }
}
