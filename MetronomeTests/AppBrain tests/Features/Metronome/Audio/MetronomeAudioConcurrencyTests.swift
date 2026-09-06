import Foundation
import Observation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct MetronomeAudioConcurrencyTests {
    @Test(.timeLimit(.minutes(1)))
    func audioReceivesTempoAndPatternChangesWithoutAnyUITicks() async throws {
        let audio = RecordingMetronomeAudioPlayer()
        let manager = makeTestMetronome(audioPlayer: audio, ticker: ControllableMetronomeTicker())
        try await manager.startPlayback()
        await audio.waitForSchedule()
        #expect(audio.scheduledPatterns.last?.interval == 0.5)
        manager.updateBPM(120)
        await audio.waitForSchedule()
        #expect(audio.scheduledPatterns.last?.interval == 0.25)
        manager.toggleGridCell(row: 0, col: 0)
        await audio.waitForSchedule()
        #expect(audio.scheduledPatterns.last?.beats[0] == nil)
        #expect(audio.playedAccents.isEmpty)
        await manager.togglePlayback()
        #expect(audio.stopCallCount == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func repeatedRequestsShareThePendingStart() async throws {
        let audio = SuspendedMetronomeAudioPlayer()
        audio.suspendedOperation = .start
        let ticker = ControllableMetronomeTicker()
        let manager = makeTestMetronome(audioPlayer: audio, ticker: ticker)
        let first = Task { try await manager.startPlayback() }
        await audio.waitForSuspension()
        let entered = AsyncStream<Void>.makeStream()
        let second = Task {
            entered.continuation.yield()
            try await manager.startPlayback()
        }
        var events = entered.stream.makeAsyncIterator()
        await events.next()
        audio.finishOperation()
        try await first.value
        try await second.value
        #expect(audio.commands == ["start"])
        #expect(ticker.startCallCount == 1)
        await manager.togglePlayback()
    }

    @Test(.timeLimit(.minutes(1)))
    func stopDuringStartPreventsLatePlaybackAndAllowsRestart() async throws {
        let audio = SuspendedMetronomeAudioPlayer()
        audio.suspendedOperation = .start
        let ticker = ControllableMetronomeTicker()
        let manager = makeTestMetronome(audioPlayer: audio, ticker: ticker)
        let start = Task { try await manager.startPlayback() }
        await audio.waitForSuspension()
        #expect(manager.isStartingPlayback)
        #expect(!manager.isPlaying)
        let stopped = AsyncStream<Void>.makeStream()
        withObservationTracking {
            _ = manager.isStartingPlayback
        } onChange: {
            stopped.continuation.yield()
        }
        let stop = Task { await manager.togglePlayback() }
        var events = stopped.stream.makeAsyncIterator()
        await events.next()
        #expect(!manager.isStartingPlayback)
        #expect(audio.commands == ["start"])
        let restart = Task { try await manager.startPlayback() }
        audio.finishOperation()
        await #expect(throws: CancellationError.self) { try await start.value }
        await stop.value
        try await restart.value
        #expect(audio.commands == ["start", "stop", "start"])
        #expect(ticker.startCallCount == 1)
        #expect(manager.isPlaying)
        #expect(!manager.isStartingPlayback)
        await manager.togglePlayback()
    }

    @Test(.timeLimit(.minutes(1)))
    func stopWaitsForInFlightClickWithoutAllowingAnotherBeat() async throws {
        let audio = SuspendedMetronomeAudioPlayer()
        let ticker = ControllableMetronomeTicker()
        let manager = makeTestMetronome(audioPlayer: audio, ticker: ticker)
        try await manager.startPlayback()
        audio.suspendedOperation = .click
        let tick = Task { await manager.tapTempo() }
        await audio.waitForSuspension()
        let stopped = AsyncStream<Void>.makeStream()
        withObservationTracking {
            _ = manager.isPlaying
        } onChange: {
            stopped.continuation.yield()
        }
        let stop = Task { await manager.togglePlayback() }
        var events = stopped.stream.makeAsyncIterator()
        await events.next()
        #expect(!manager.isPlaying)
        await ticker.sendTick()
        audio.finishOperation()
        await tick.value
        await stop.value
        #expect(audio.commands == ["start", "click", "stop"])
        #expect(!manager.isPlaying)
        #expect(manager.currentBeat == -1)
    }

    @Test(.timeLimit(.minutes(1)))
    func startupLoadsPresetsWhileAudioPreparationIsSuspended() async {
        let audio = SuspendedMetronomeAudioPlayer()
        audio.suspendedOperation = .prepare
        let repository = SuspendedPresetRepository()
        let manager = makeTestMetronome(presetRepository: repository, audioPlayer: audio)
        let brain = AppBrain(metronome: manager)
        let launch = Task { await brain.applicationDidFinishLaunching() }
        await audio.waitForSuspension()
        await repository.waitForLoad()
        #expect(manager.isLoadingPresets)
        repository.finishLoad()
        audio.finishOperation()
        await launch.value
        #expect(!manager.isLoadingPresets)
        #expect(!manager.isPlaying)
    }

    @Test func liveAudioUsesAnOffMainExecutor() async {
        let audio = AVFoundationMetronomeAudioPlayer(bundle: .main)
        #expect(await audio.executesOffMainThread())
        MainActor.assertIsolated()
    }
}

private extension AVFoundationMetronomeAudioPlayer {
    func executesOffMainThread() -> Bool {
        assertIsolated()
        return !Thread.isMainThread
    }
}
