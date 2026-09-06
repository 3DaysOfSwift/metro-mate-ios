# Concurrency Inventory

## Current Implementation

The table below is the original planning inventory, not a current list of
unimplemented work. Its pending labels describe the baseline assessment.

| Original entries | Current owner and implementation | Remaining verification |
| --- | --- | --- |
| CON-001–004 | Main-actor MetronomeManager uses SwiftConcurrencyMetronomeTicker; a stored task waits on ContinuousClock deadlines and is cancelled when replaced or stopped. First playback tick retains a 10 ms delay. | Real-device cadence, first-beat latency, and behaviour under load |
| CON-005 | SwiftConcurrencyDelayScheduler owns pulse-completion tasks. Overlapping completions are retained to preserve the existing behaviour; stop cancels them. | Visual comparison and explicit review of stop-time cancellation |
| CON-006 | NoteValuePickerViewModel owns and cancels its 200 ms dismissal task. | Repeated selection and dismissal on screen |
| CON-007 | Feature-owned tap-reset scheduler replaces its task on each tap. | Run deterministic reset tests in Xcode |
| CON-008 | Unused tap-point implementation removed. | Confirm no missing visual behaviour in regression testing |
| CON-009 | ContentViewModel owns the repeating adjustment task. | Long press, release, bounds, and screen lifetime |
| CON-010 | StarFieldViewModel owns its animation task and cancels on disappearance. | Visual comparison and lifetime checks |

The production-source scan finds no explicit DispatchQueue, DispatchSource,
scheduledTimer, or Timer construction. This proves syntax replacement, not
timing equivalence. Cooperative tasks are not real-time audio scheduling:
device testing under load remains essential before declaring this migration done.

## Original Planning Inventory

Do not replace an entry merely to remove GCD syntax. Preserve the guarantee
listed here and record the evidence that proves the replacement behaves the
same way. A deliberate decision to retain a suitable system primitive is a
valid resolution.

| ID | Legacy primitive and location | Existing purpose and guarantee | Lifetime | Intended evaluation | Required evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| CON-001 | `DispatchSourceTimer` created by playback start | Produces repeating, user-interactive beat deadlines after the immediate first beat | Durable until playback stops or timing changes | Compare a clock-based Swift task with retaining `DispatchSourceTimer`; accuracy wins over syntactic conversion | Automated cadence tests plus real-device timing observation under load | Pending |
| CON-002 | Recreated `DispatchSourceTimer` in BPM, note-value, preset, randomise, and reset changes | Cancels the old timing source before applying a new interval so only one playback clock remains | Replaceable | Centralise replacement ownership before changing primitive | Prove one active clock, correct new interval, and no stale ticks | Pending |
| CON-003 | `DispatchQueue.main.async` inside timer handlers | Transfers beat-state and UI-observed mutation from the private timer queue to the main thread | One hop per timer event | Replace with explicit actor isolation only after the feature boundary exists | Strict-concurrency build and isolation tests; no off-actor state mutation | Pending |
| CON-004 | 10 ms `DispatchQueue.main.asyncAfter` before first playback tick | Allows the audio system to become ready, then emits the first beat before the repeating timer begins | One-shot per start | Determine whether the delay is a product requirement or implementation workaround | Compare first-beat latency and audio reliability before and after | Pending |
| CON-005 | 100 ms `DispatchQueue.main.asyncAfter` for visual blink | Returns transient visual pulse state to false | Replaceable one-shot | Likely ViewModel-owned replaceable Task after presentation extraction | Rapid-event test proving an older reset cannot shorten a newer pulse | Pending |
| CON-006 | 200 ms delayed sheet dismissal in note-value and preset selection | Keeps the selection feedback visible before dismissing presentation | One-shot UI transition | ViewModel or View-owned unretained Task depending whether cancellation/tracking is required | UI test confirming selection applies once and dismissal remains visually equivalent | Pending |
| CON-007 | Foundation timer for tap-count clearing | Clears the visible tap count after three seconds of inactivity while preserving BPM | Replaceable | ViewModel-owned replaceable Task with injected clock | Deterministic inactivity and stale-clear tests | Pending |
| CON-008 | Foundation timer for tap-point animation | Mutates tap-point scale and opacity every 20 ms and stops when no active points remain | Tracked visual animation | Prefer native SwiftUI animation if it preserves appearance; otherwise ViewModel-owned managed work | Visual/manual comparison and lifetime test after View removal | Pending |
| CON-009 | Foundation timers in `ContentView` for press-and-hold BPM changes | Repeats increment or decrement every 100 ms until the press ends | Tracked screen interaction | Must move out of the View; evaluate a ViewModel-owned cancellable Task | Holding, release, disappearance, bounds, and cancellation tests | Pending |
| CON-010 | Foundation timer in `StarFieldView` at 60 Hz | Continuously updates decorative dot positions | Long-lived while presentation exists | Replace with SwiftUI animation/timeline where behaviour remains equivalent, otherwise ViewModel-owned managed work | Confirm animation stops with screen lifetime and appearance remains acceptable | Pending |

## Risks Recorded Before Migration

- `MetronomeManager` publishes mutable state without actor isolation while its
  timer originates on a private queue.
- Timer construction is duplicated across several commands, increasing the
  chance that one path preserves different behaviour.
- Loading a preset while playing invokes `tick()` twice for every timer event.
  The behaviour contract records this as conflicting evidence rather than
  silently preserving or correcting it.
- Several delayed closures strongly capture their owner and have no explicit
  replacement or cancellation policy.
