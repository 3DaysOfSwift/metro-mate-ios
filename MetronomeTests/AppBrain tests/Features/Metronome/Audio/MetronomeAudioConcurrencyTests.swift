import Foundation
import Observation
import Testing
@testable import Metronome

@MainActor
@Suite(.serialized)
struct MetronomeAudioConcurrencyTests {
    @Test(.timeLimit(.minutes(1)))
    func productionPlayerKeepsItsTimelineThroughRapidTempoChanges() async throws {
        let audio = AVFoundationMetronomeAudioPlayer(bundle: .main)
        do {
            let source = MetronomePlaybackPattern(interval: 0.1, beats: [true, false], restartFromFirstBeat: true)
            try await audio.schedulePlayback(source, initialDelay: 0)
            // Wait for the real engine to render, not an assumed simulator startup time.
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: .seconds(5))
            while await audio.playbackBeat() == nil, clock.now < deadline {
                try await Task.sleep(for: .milliseconds(20))
            }
            var previous = try #require(await audio.playbackBeat())
            let first = previous
            for step in 0..<60 {
                let pattern = MetronomePlaybackPattern(
                    interval: 0.1 - Double(step % 20) * 0.001,
                    beats: source.beats, restartFromFirstBeat: false
                )
                // A replacement would postpone sound by a whole beat. Tempo edits
                // must ignore this startup delay and preserve the existing timeline.
                try await audio.schedulePlayback(pattern, initialDelay: pattern.interval)
                try await Task.sleep(for: .milliseconds(20))
                let beat = try #require(await audio.playbackBeat())
                #expect(beat >= previous)
                previous = beat
            }
            #expect(previous >= first + 4)
            let changed = MetronomePlaybackPattern(interval: 0.05, beats: [nil, true, false], restartFromFirstBeat: true)
            try await audio.schedulePlayback(changed, initialDelay: 0.5)
            try await Task.sleep(for: .milliseconds(250))
            let progress = try #require(try await audio.playbackProgress())
            #expect(progress.step > previous)
            #expect((0..<3).contains(try #require(progress.beatIndex)))
            await audio.stop()
            try await Task.sleep(for: .milliseconds(100))
            #expect(await audio.playbackBeat() == nil)
            try await audio.schedulePlayback(source, initialDelay: 0)
            let restartDeadline = clock.now.advanced(by: .seconds(5))
            while await audio.playbackBeat() == nil, clock.now < restartDeadline {
                try await Task.sleep(for: .milliseconds(20))
            }
            let restarted = try #require(try await audio.playbackProgress())
            #expect(restarted.step < progress.step)
            #expect(restarted.skippedBeats == 0)
            await audio.stop()
        } catch {
            await audio.stop()
            throw error
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func rapidTempoChangesNeverRequestARestartEvenBeforeTheFirstUIPoll() async throws {
        let audio = RecordingMetronomeAudioPlayer()
        let ticker = ControllableMetronomeTicker()
        let manager = makeTestMetronome(audioPlayer: audio, ticker: ticker)
        try await manager.startPlayback()
        await audio.waitForSchedule()
        for bpm in 61...100 {
            manager.updateBPM(Double(bpm))
            await audio.waitForSchedule()
            #expect(audio.scheduledPatterns.last?.restartFromFirstBeat == false)
        }
        let count = audio.scheduledPatterns.count
        manager.updateBPM(100)
        #expect(audio.scheduledPatterns.count == count)
        #expect(ticker.startCallCount == 1)
        #expect(audio.stopCallCount == 0)
        await manager.togglePlayback()
    }

    @Test(.timeLimit(.minutes(1)))
    func rapidPatternEditsKeepOnlyTheLatestPendingConfiguration() async throws {
        let audio = SuspendedMetronomeAudioPlayer()
        let manager = makeTestMetronome(audioPlayer: audio)
        try await manager.startPlayback()
        await audio.waitForSchedule()
        audio.suspendedOperation = .schedule
        manager.updateBPM(100)
        await audio.waitForSuspension()
        await audio.waitForSchedule()
        for bpm in 101...200 { manager.updateBPM(Double(bpm)) }
        #expect(audio.scheduledPatterns.count == 2)
        audio.finishOperation()
        await audio.waitForSchedule()
        #expect(audio.scheduledPatterns.count == 3)
        #expect(audio.scheduledPatterns.last?.interval == 0.15)
        await manager.togglePlayback()
    }

    @Test(.timeLimit(.minutes(1)))
    func patternReplacementRejectsAnInFlightProgressSnapshot() async throws {
        let audio = SuspendedMetronomeAudioPlayer()
        let ticker = ControllableMetronomeTicker()
        let manager = makeTestMetronome(audioPlayer: audio, ticker: ticker)
        try await manager.startPlayback()
        audio.currentPlaybackBeat = 3
        audio.suspendedOperation = .progress
        let poll = Task { await ticker.sendTick() }
        await audio.waitForSuspension()
        manager.toggleBeat(at: 0)
        audio.finishOperation()
        await poll.value
        #expect(manager.currentBeat == -1)
        #expect(!manager.shouldBlink)
        audio.currentPlaybackBeat = 0
        await ticker.sendTick()
        #expect(manager.currentBeat == 0)
        await manager.togglePlayback()
    }

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
        manager.toggleBeat(at: 0)
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
