import Testing
@testable import Metronome

@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct SwiftConcurrencyMetronomeTickerTests {
    @Test func stopBeforeTheFirstDeadlinePreventsTheCallback() async throws {
        let ticker = SwiftConcurrencyMetronomeTicker()
        var calls = 0
        ticker.start(after: .milliseconds(50), repeatingEvery: .milliseconds(20)) {
            calls += 1
        }
        ticker.stop()
        try await Task.sleep(for: .milliseconds(150))
        #expect(calls == 0)
    }

    @Test func replacementCancelsThePreviousSleepingTask() async throws {
        let ticker = SwiftConcurrencyMetronomeTicker()
        var oldCalls = 0
        var newCalls = 0
        let arrived = AsyncStream<Void>.makeStream()
        ticker.start(after: .milliseconds(50), repeatingEvery: .milliseconds(20)) {
            oldCalls += 1
        }
        ticker.start(after: .zero, repeatingEvery: .seconds(10)) {
            newCalls += 1
            arrived.continuation.yield()
        }
        var events = arrived.stream.makeAsyncIterator()
        await events.next()
        ticker.stop()
        try await Task.sleep(for: .milliseconds(150))
        #expect(oldCalls == 0)
        #expect(newCalls == 1)
    }

    @Test func stopDuringASuspendedCallbackPreventsFurtherTicks() async throws {
        let ticker = SwiftConcurrencyMetronomeTicker()
        let gate = SuspendedTick()
        var calls = 0
        ticker.start(after: .zero, repeatingEvery: .milliseconds(10)) {
            calls += 1
            await gate.suspend()
        }
        await gate.waitForArrival()
        ticker.stop()
        gate.resume()
        try await Task.sleep(for: .milliseconds(100))
        #expect(calls == 1)
    }

    @Test func replacementDuringACallbackDoesNotReviveTheOldLoop() async throws {
        let ticker = SwiftConcurrencyMetronomeTicker()
        let gate = SuspendedTick()
        var oldCalls = 0
        var newCalls = 0
        ticker.start(after: .zero, repeatingEvery: .milliseconds(10)) {
            oldCalls += 1
            await gate.suspend()
        }
        await gate.waitForArrival()
        let arrived = AsyncStream<Void>.makeStream()
        ticker.start(after: .zero, repeatingEvery: .seconds(10)) {
            newCalls += 1
            arrived.continuation.yield()
        }
        var events = arrived.stream.makeAsyncIterator()
        await events.next()
        ticker.stop()
        gate.resume()
        try await Task.sleep(for: .milliseconds(100))
        #expect(oldCalls == 1)
        #expect(newCalls == 1)
    }

    @Test func destructionCancelsTheSleepingTask() async throws {
        var ticker: SwiftConcurrencyMetronomeTicker? = SwiftConcurrencyMetronomeTicker()
        var calls = 0
        ticker?.start(after: .milliseconds(50), repeatingEvery: .milliseconds(20)) {
            calls += 1
        }
        ticker = nil
        try await Task.sleep(for: .milliseconds(150))
        #expect(calls == 0)
    }

    @Test func callbackLongerThanTheIntervalDoesNotOverlapCallbacks() async throws {
        let ticker = SwiftConcurrencyMetronomeTicker()
        let finished = AsyncStream<Void>.makeStream()
        var calls = 0
        var activeCallbacks = 0
        var maximumActiveCallbacks = 0
        ticker.start(after: .zero, repeatingEvery: .milliseconds(20)) {
            activeCallbacks += 1
            maximumActiveCallbacks = max(maximumActiveCallbacks, activeCallbacks)
            calls += 1
            if calls == 1 {
                // Miss several deadlines without blocking the Main Actor.
                try? await Task.sleep(for: .milliseconds(120))
            }
            activeCallbacks -= 1
            if calls == 4 {
                ticker.stop()
                finished.continuation.yield()
            }
        }
        var events = finished.stream.makeAsyncIterator()
        await events.next()
        #expect(calls == 4)
        #expect(maximumActiveCallbacks == 1)
    }

    @Test func missedVisualPollsWaitForANewIntervalInsteadOfCatchingUp() async throws {
        let ticker = SwiftConcurrencyMetronomeTicker()
        let clock = ContinuousClock()
        let finished = AsyncStream<Void>.makeStream()
        let interval = Duration.milliseconds(80)
        var firstCompletion: ContinuousClock.Instant?
        var secondStart: ContinuousClock.Instant?
        ticker.start(after: .zero, repeatingEvery: interval) {
            if firstCompletion == nil {
                // Make multiple deadlines overdue without blocking the UI executor.
                try? await clock.sleep(for: .milliseconds(250))
                firstCompletion = clock.now
            } else {
                secondStart = clock.now
                ticker.stop()
                finished.continuation.yield()
            }
        }
        var events = finished.stream.makeAsyncIterator()
        await events.next()
        let completion = try #require(firstCompletion)
        let nextStart = try #require(secondStart)
        // Only a lower bound: a busy simulator is allowed to deliver late.
        #expect(completion.duration(to: nextStart) >= interval)
    }
}

@MainActor
private final class SuspendedTick {
    private let arrived = AsyncStream<Void>.makeStream()
    private var continuation: CheckedContinuation<Void, Never>?

    func suspend() async {
        await withCheckedContinuation {
            continuation = $0
            arrived.continuation.yield()
        }
    }

    func waitForArrival() async {
        var events = arrived.stream.makeAsyncIterator()
        await events.next()
    }

    func resume() {
        let pending = continuation
        continuation = nil
        pending?.resume()
    }
}
