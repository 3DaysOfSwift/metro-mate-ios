# AppBrain Migration Ledger

## Pass Fifteen Follow-up: Ordered Edits and Coalescing

At the developer's request, preset edits now establish arrival order before
awaiting initial loading. Each applied edit submits its latest collection before
the next edit runs. A single durable writer keeps one active snapshot and one
latest pending snapshot. Intermediate writes may be combined, but every applied
edit is represented in the resulting collection unless a later edit deliberately
replaces or deletes it. Callers await the writer; latest failures remain retryable.

Replaceable rhythm updates also use one worker and a latest pending pattern,
rather than appending an audio operation for each change while the audio executor
is busy. Added tests for same-name edits during initial loading, coalesced writes
under suspended storage, and rapid rhythm edits under suspended audio scheduling.

These changes bound pending snapshots/configurations, not the number of callers
or nonreplaceable commands. Initial-load waiters and explicitly ordered clicks,
starts, and stops remain lossless; rejecting those under arbitrary sustained
input would require an explicit admission policy. Manual verification remains
with the developer. The complete MetronomeTests target passed on 7 September
2026 after these changes; UI tests and device profiling were not rerun.

## Pass Fifteen: Concurrency Review — 7 September 2026

Validation: the complete MetronomeTests target passed on the iPhone Air simulator
with complete concurrency checking enabled, including the new suspended-progress
regression test. UI tests and physical-device profiling were not rerun.

Reviewed launch, playback start/stop and replacement, visual polling, preset
load/save/retry, and presentation task lifetimes. Found and corrected a stale
visual-result window: a poll suspended in playbackBeat() could publish after a
pattern edit that does not restart the ticker. The poll now checks both ticker
and pattern revisions after suspension. A controlled-suspension test replaces
the pattern during that read and verifies that the old beat and blink are not
published, then verifies a subsequent poll can update the display.

Retained guarantees and their evidence:

- Launch uses independent async-let audio preparation and preset loading;
  startupLoadsPresetsWhileAudioPreparationIsSuspended exercises the overlap.
- Pending starts share a Task; playback revisions and ordered audio operations
  protect stop/restart. Suspended-start and suspended-click tests exercise them.
- Preset loading is shared. Committed writes await their predecessor and ignore
  older failures; overlappingSavesPreserveOrderAndIgnoreAnOlderFailure also
  checks that cancelling the caller does not discard its write.
- Presentation tasks use cancellation and weak ownership. Star-field frames
  are awaited one at a time and rejected on cancellation or canvas replacement;
  ticker callbacks do not overlap and overdue visual polls are skipped.
- Audio and storage use isolated serial executors; render inputs are Sendable
  values. Existing executor tests complement complete concurrency checking.

Limits: ordered audio commands and durable preset writes have no fixed queue
capacity; a persistently slow external API under sustained submissions could
accumulate pending work. Revision checks skip obsolete queued pattern work but
do not preempt an already running synchronous audio operation. No new admission
or command-dropping policy was introduced, since that requires a product
decision. This is a recorded residual risk, not an approved deferral or a claim
of bounded memory under arbitrary load. Exact ordering among commands awaiting
the same initial preset load is not established by the current overlapping-save
test. Hardware profiling and manual approval of this checkpoint remain pending.

## Pass Fourteen: Main Actor Review Refinements — 7 September 2026

The developer approved simulator audio playback and reported all tests passing
for the preceding implementation. The subsequent Main Actor review identified
two refinements, now implemented: visual polling skips overdue deadlines instead
of catching up, and default, loaded, and random beat patterns are built in local
arrays before each array is published once. Reset no longer clears observed
arrays redundantly before default-pattern construction clears them.

Audio scheduling and persistence ownership are unchanged. A new real-ticker
test checks that a delayed callback is followed by a fresh interval, alongside
existing cancellation, replacement, and non-overlap tests. These changes do not
claim measured performance gains; manual regression approval of this checkpoint
remains pending.

Validation: the complete MetronomeTests target passed on the iPhone Air simulator
on 7 September 2026, including the new missed-poll test. MetronomeUITests was not
rerun for this checkpoint. `git diff --check` passed.

## Migration Closed — 6 September 2026

The developer requested completion after general manual app approval and the
explicit deferral of further timing/profiling work. The final MetronomeTests
simulator run passed against application commit
`78ce4fff052b3256861e861b3d6fa16ee1bbbc05`.
The closing source/ownership audit and feature-by-feature handover are recorded
in [MIGRATION_FEATURE_REPORT.md](MIGRATION_FEATURE_REPORT.md).

This is completion of the agreed migration scope, not a claim that every
device regression or performance check passed. Hardware-specific and measured
timing checks remain documented follow-ups. Entries below retain the historical
state at each checkpoint; the Starting Architecture table is not a current
backlog. Consult the final report for current ownership and evidence limits.

## Pass Twelve: Swift Observation — Implemented, Manual UI Check Pending

### Reopened: User-reported Irregular Playback

### Corrective Execution Refactor — Awaiting Listening Approval

At the developer's request, repeating sound now uses a rendered rhythm buffer
looped by AVAudioPlayerNode rather than clicks triggered by Main Actor ticks.
Beat positions are spaced in audio samples, with silence and overlapping tails
mixed into the loop. Bundled 44.1 kHz click samples and fallback samples are
cached on the audio executor. Tap feedback remains separate. The display polls
the audio playhead and skips visual updates it missed instead of replaying sound.

Tempo/pattern edits replace the loop and schedule its next start after the new
interval, retaining the next beat where possible; note/count resets start at
beat zero. Replacement rebuilds and resets the player timeline, so transition
quality must be verified by listening. Sample periods are rounded to whole
frames. This is a deliberate scheduling change, not a claim of exact legacy
timing equivalence or immunity from audio-device overload/interruption.

StarFieldRenderer calculates frames on its own actor from value inputs. One
animation task awaits each result; it rejects stale canvas revisions and
cancelled frames. The ViewModel is not retained across frame calculation.

Added sample-layout, silence/accent, tail-overlap, rotation, and invalid-timing
tests; a no-UI-ticks configuration test; and renderer executor/resize tests.
Existing playback tests now model audio progress independently of UI polling.
The complete MetronomeTests run passed on the iPhone Air simulator on 6 September
2026. It includes an offline audio-engine test that renders repeated pulses and
checks their sample spacing without UI ticks. This validates the loop mechanics,
not real-time hardware performance or the production player's live transitions.
These automated checks do not establish speaker timing. Keep this regression
open until continuous playback, tempo/preset edits, rapid stop/start, tap feedback,
and animation are heard and observed under load.

After this conversion the developer reported irregular beats and an unusable
metronome. This overrides any implication that passing state tests establishes
product correctness. Pass Twelve remains open until audible playback is verified.

The star-field loop mutated its observed nested array once per dot on the Main
Actor, which also triggers playback ticks. The first corrective change builds
an ordinary local frame and assigns the observed array once when complete.
This removes per-dot Observation mutation work without changing the visual
formula or the musical timing policy. A full-size canvas test protects frame
updates and retained snapshot values; it is not an audio timing test.

The attempted pre-change targeted run did not provide a usable timing baseline.
No before/after latency figure or confirmed root cause is claimed. Playback still
depends on Main Actor tick delivery; reducing animation overhead alone does not
establish that sound remains regular under UI load. Manual listening and further
timing investigation are required if the regression persists.

Requested after migration closure; this does not invalidate the completed
migration milestone. MetronomeManager, all eight dedicated ViewModels, and
ThemeManager now use @Observable with their existing Main Actor isolation.
MetronomeFeature requires Observable instead of a Combine publisher. Manual
notification subscriptions and @Published have been removed from production
and tests. Screens and the app-owned theme now use @State; task handles and
internal scheduling bookkeeping are excluded from observation.

The agreed scope was:

1. Convert MetronomeManager, the eight dedicated ViewModels, and ThemeManager
   to @Observable while retaining their Main Actor isolation. Remove Combine
   requirements from MetronomeFeature and manual notification forwarding.
2. Adapt screen-owned state and bindings, preserving ViewModel identity and
   side-effect-free construction. Keep retained task handles in their current
   owners and outside observation tracking where appropriate.
3. Replace publisher-specific tests with tracking tests through screen-facing
   computed properties and the real feature protocol. Verify shared state,
   collection changes, themes, errors/retry, and unrelated-change behaviour.
4. Run strict checks and the full relevant suite; verify sheet/navigation state
   and cancellation/lifetime behaviour. Update ARCHITECTURE.md and the feature
   report only once the implementation and evidence support the new description.

The feature remains the single state owner. Audio/storage executors, playback
ordering, persistence guarantees, and timing policy are not part of this change.
Observation replaces UI notification wiring, not Swift Concurrency itself.
The reusable pass is recorded in Trend's legacy-application-migration.md.

Five additional tests verify unrelated-change filtering and re-registration,
collection-derived tile state, selected theme tracking, observed load failure
and retry, and local draft observation. The shared-screen test now tracks both
ViewModels through their actual feature protocol. Existing task-lifetime tests
remain in place; suspended audio/save tests use one-shot Observation signals
and assert resulting state after the mutation.

The full MetronomeTests simulator suite passed with complete concurrency checking
after conversion and the additional tests. The standalone swiftc subset check
could not execute Observation's macro plugin due to its sandbox; full Xcode
compilation is the applicable build evidence. No deployment target or language
mode changed. Existing weak-variable test warnings are not new diagnostics.

Manual follow-up: open and dismiss Settings, Grid Settings, the note picker,
and Presets repeatedly; edit/cancel a preset name; verify shared beat/tempo
updates and continued animation. Unit tests do not certify SwiftUI identity or
visual dismissal. This remains explicit before the pass is marked closed.

## Pass Ten: Off-Main Feature Execution — Closed

Closed on 6 September 2026 with the developer's agreement to defer additional
cadence investigations and performance profiling to future improvement work.
Complete concurrency checking, off-main audio and persistence ownership, cached
fallback buffers, and real ticker lifecycle tests are implemented and verified
as described below. Closure records the agreed scope; it does not certify
real-time audio accuracy or measured responsiveness.

First checkpoint enables complete concurrency checking in Debug and Release
for all three targets, retaining Swift 5 language mode. App Intent metadata is
immutable and the grid-settings binding uses an explicitly inferred closure.
Fallback audio buffers are prepared once per player instead of generated on
every fallback click. No unchecked Sendable annotations were introduced.

The full generic iOS Simulator Debug build succeeds. Focused Swift typechecking
with complete checking and warnings-as-errors also succeeds (excluding the App
and root preview files; these are covered by the full build). Project syntax and
diff whitespace checks pass. The MetronomeTests suite passes on the iPhone Air
iOS 26.2 simulator. Actual fallback playback and profiling still require
verification; no measured responsiveness claim is made. Existing app-icon
and weak-variable compiler warnings remain unrelated to concurrency checking.

### Persistence Checkpoint

Moved UserDefaultsPresetRepository to an actor with a retained DispatchSerialQueue
executor. The repository creates and retains its UserDefaults instance on that
executor; only suite/key configuration enters its initializer. JSON and storage
operations no longer execute on the Main Actor. The repository contract is async
and Sendable; BeatPreset and its stored enums have checked Sendable conformances.

MetronomeManager shares a pending load, serializes committed write snapshots with
awaited task dependencies, and prevents stale save completions from publishing
errors for newer edits. A save captures the requested configuration before
loading suspends. Loading/saving state is exposed through the dedicated ViewModel.
Existing load failures, optimistic edits, save failures, and retry remain visible.
The launch callback and relevant screen actions now await persistence.

Added controlled-suspension tests for shared loads, snapshot capture, ordered
writes, stale failure suppression, and writes surviving caller cancellation.
Updated existing persistence and ViewModel tests to await completion. The live
repository also has an executor check when invoked from the Main Actor.

Validation: the full MetronomeTests run passes on the iPhone Air iOS 26.2
simulator, including the executor test and all four newly added tests.
Focused production-source typechecking passes with complete concurrency
checking and warnings-as-errors. No unchecked conformance was added.

This bounded persistence conversion was taken before audio because its existing
tests make the new await boundaries directly verifiable. No before/after device
profile was captured; off-main ownership is not a measured performance claim.

### Audio Checkpoint

AVFoundationMetronomeAudioPlayer is now a serial-executor actor with async
protocol operations. Session activation, engine setup, resource loading,
fallback generation, click scheduling, and stopping execute off-main. Engine
and player construction occurs on that executor on explicit use, not in init.
Apple's synchronous [session activation API](https://developer.apple.com/documentation/avfaudio/avaudiosession/setactive(_:options:))
and [engine start API](https://developer.apple.com/documentation/avfaudio/avaudioengine/start())
remain encapsulated below the feature.

MetronomeManager orders audio commands using awaited task dependencies and shares
a pending playback start. Stop invalidates the start and queued old ticks before
awaiting hardware cleanup. No synchronous device call is assumed preemptible.
The ticker awaits its async callback rather than launching overlapping clicks;
the existing deadline progression is retained for the later cadence review.
Playback is still durable; an explicit Stop cancels a pending start, whereas a
single awaiting caller disappearing does not implicitly stop shared playback.

The ViewModel exposes a starting state and its UI permits cancelling preparation.
AppBrain uses async let to begin audio and preset loading independently.
Added five tests: shared pending start, stop/start replacement, in-flight click
ordering, concurrent launch loads, and the live audio actor's off-main executor.
Existing playback/failure tests now await completed operations.

Validation: the full MetronomeTests simulator run passes after the final changes,
including all five new audio concurrency tests. Focused production-source
typechecking with complete checking and warnings-as-errors passes. Device audio
quality, fallback playback, and combined-load latency are not claimed verified.

### Real Ticker Checkpoint

Added six tests using SwiftConcurrencyMetronomeTicker itself, not its controllable
test double. They cover cancellation before the first deadline, replacement
while sleeping, stop and replacement during a suspended callback, destruction,
and non-overlapping callbacks when work exceeds the interval. The tests suspend
cooperatively and use bounded observation windows, with no tight upper-bound
latency assertions that would be unreliable on a busy CI machine.

Documented the existing missed-deadline policy in the implementation: advance
from the planned deadline, not callback completion. This can produce catch-up
bursts. No scheduling or musical behaviour was changed. The delayed-callback
test verifies non-overlap, not the spacing or musical suitability of catch-up
ticks. That remains a profiling and product-policy decision.

Verification: the full MetronomeTests automated suite passed on the iPhone Air
simulator, including these six real-ticker tests. This does not replace device
profiling or manual audio regression checks.

### Future Improvements and Outstanding Manual Verification

These are recorded follow-ups, not blockers to the agreed Pass Ten closure.
Unperformed checks remain unverified rather than being counted as passed.

1. Capture a combined cold-start, star-field animation, and playback baseline
   using Instruments on a representative device. Include missing audio files
   and preset loading/saving. No latency or frame-time measurements exist yet.
2. Verify bundled and fallback audio by listening on device, including rapid
   start/stop, tempo changes, and simultaneous animation.
3. Measure real ticker cadence and catch-up spacing under animation load.
   A future Swift diagnostic can record ContinuousClock callback timestamps
   after deliberately suspending one callback. Deterministic deadline-policy
   tests can complement those observations without tight real-time assertions.
   Agree on any change to the existing late-tick policy before implementing it.
4. Repeat profiling, strict checking, and regressions. Move costly animation
   calculations off-main only if measurements warrant it, publishing completed
   frames without stale results. Do not add Task.yield merely as a showcase.

The audio and persistence ownership changes and real ticker lifetime tests are
complete within this pass. Catch-up diagnostics are a future test-suite
enhancement; fallback playback and device performance remain unverified.
No production behaviour was changed to close the pass. The final migration
audit and feature behaviour report should retain these evidence limits.

## Pass Seven: Feature-owned Model Files

Moved all eight audio, preset-storage, and timing source files beneath
Features/Metronome. Their sole feature consumer is MetronomeManager; AppBrain
continues to construct them. AppBrain.swift is the only Model-layer file outside
the feature, justified by its application-wide composition responsibility.
No source contents, resources, or runtime behaviour changed.

## Pass Eight: Test Grouping Implemented

- Split mixed AppBrainTests: retain composition/launch tests there, move
  feature persistence/audio tests to Metronome tests, and observation tests
  to the appropriate ViewModel or cross-screen integration group.
- Split SheetViewModelTests and VisualViewModelTests into focused suites.
- Group domain, audio, timing, and repository tests beneath Metronome where
  applicable; retain genuinely shared test support without duplication.
- Preserve assertions and update behaviour-contract test references.
- Review the resulting groups for coverage gaps and record bounded follow-ups,
  including clock cadence verification, separately from folder changes.

The grouping above is now implemented. All 22 test bodies redistributed from
AppBrainTests, SheetViewModelTests, and VisualViewModelTests are unchanged.
The two mixed screen suites were removed; their tests now live in the six
matching screen suites. The load-error presentation test also moved from
AppBrainTests into BeatPresetsViewModelTests. Cross-screen observation and
dependency wiring live in SharedFeatureObservationTests. Existing feature,
domain, repository, and theme suites were moved intact. Shared test doubles
remain shared. No production files changed in this pass.

### Further Refinement Plan

- Timing: compare real clock cadence under load against the baseline; a
  change to missed-deadline policy requires an explicit behavioural decision.
- Test reliability: review sleep-based animation tests under repeated Xcode
  runs; introduce controllable time only if failures or excessive runtime
  justify it. Do not replace existing runtime coverage with fake-only tests.
- Domain tests: NoteValueTests also covers GridDisplayMode labels. A later
  small naming/splitting pass can make that ownership clearer without changing
  assertions; it is not a blocker to this regrouping.
- Observation: retain the documented Combine decision for this migration.
  Any move to Observation remains a separately scoped and tested change.

Completion requires an Xcode run after suite splitting. Serialisation is
retained within each split suite; Swift Testing may run independent suites
concurrently, so the full run must verify there is no hidden shared test state.

## Remaining Review

The presentation-subview pass removed the two closure-fed picker button View
types in favour of private rendering functions on their owning screen.
Decorative dot counts moved to NoteValuePickerViewModel with a regression test.
All remaining custom View structs have dedicated ViewModels; BeatTile retains
its beat identity input. Manual regression and final evidence reconciliation
remain outstanding.

The latest boundary pass made every screen ViewModel's feature reference private,
removed direct feature access from Views, and centralised the remaining hard-coded
tempo limits. A two-screen notification test was added for the retained Combine
forwarding. Production subset typechecking passes; the new test needs an Xcode run.

The GCD/timer replacement implementation and folder organisation are in place.
The older per-pass entries below retain historical verification notes; they
must not be read as a fresh test-run report.

- Review Combine observation forwarding and direct View access to feature APIs
  against the template before deciding the scope of an Observation conversion.
- Review presentation-only subviews against the dedicated ViewModel convention.
- Finish manual regression journeys, including Siri, saved presets, failure
  recovery, and audio timing on a device under load.
- Reconcile the behaviour contract and test evidence before declaring completion.

Haptics are now created by screen ViewModels, not SwiftUI Views. This is an
appropriate presentation responsibility; an additional feature manager is not
required. The three deprecated onChange handlers now use the two-parameter
form supported by the existing deployment target, without initial invocation.

## Siri Feature Boundary Pass

Siri now requests startPlayback() or startPlayback(atBPM:) from the metronome
feature instead of inspecting playback state and coordinating commands itself.
The feature owns start-only behaviour, tempo application, and failure propagation.
Siri retains parameter conversion and response wording. Repeated start requests
must leave playback running; specifying a tempo while playing retains the existing
retiming behaviour. Added direct feature tests for these paths and audio retry.
Grid layout and visual highlighting remain presentation responsibilities.

## Explicit Loading Pass

Feature construction now assigns dependencies and builds in-memory defaults only.
AppBrain.applicationDidFinishLaunching() explicitly warms audio and requests saved
presets when the root screen appears. The preset screen also requests its data;
successful loads are retained by the feature and failed loads expose an error
with a Retry action. Saving and deleting first ensure existing presets have
loaded, preventing an unsuccessful read from causing a storage overwrite.
Playback retains its existing audio readiness check, including the Siri path.

Added tests for side-effect-free construction, launch loading, repeated successful
requests, saving before launch, and failure/retry. Production subset typechecking
passed; full Xcode build and test execution remain to be verified. Audio readiness
failure handling and preset save-error presentation are implemented in the next
pass below.

## Audio and Save Failure Pass

Audio preparation, playback start, and click scheduling now propagate errors to
the feature. Preparation only becomes successful after setup completes; a retry
does not attach the audio node twice. Playback stays stopped when starting fails
and stops if a click fails. The main screen exposes audio failure and a retry
action; Siri no longer announces successful playback after an audio failure.
The existing generated-click fallback for missing audio files is retained.

Failed preset writes retain the edited collection in memory, explicitly show
that changes are not saved, and allow retrying the collection without repeating
the edit. These pending edits are not durable until the write succeeds.
Added failure/recovery tests. Full runtime verification remains an Xcode step.

## Starting Architecture

The current folder structure is documented in [ARCHITECTURE.md](ARCHITECTURE.md).
Screens formerly grouped in ContentView.swift now have separate files beside
their ViewModels. Musical data types live with the metronome feature.

The original application places most presentation, feature, audio, timing, and
persistence responsibilities in two files: `ContentView.swift` and
`MetronomeManager.swift`. This ledger records temporary ownership explicitly so
that no responsibility becomes stranded during the staged migration.

| Responsibility | Original owner | Transitional owner | Intended owner | Why transitional | Resolving pass | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Root metronome-screen presentation state and user intent | `ContentView` | `ContentViewModel` | `ContentViewModel` | Screen needs one dedicated backing object before Model extraction | Pass One | Complete |
| Settings presentation state and intent | `SettingsView` in `ContentView.swift` | `SettingsViewModel` | `SettingsViewModel` | Separate screen currently talks directly to the shared manager | Pass One | Complete |
| Grid-settings presentation state and intent | `GridSettingsView` in `ContentView.swift` | `GridSettingsViewModel` | `GridSettingsViewModel` | Separate screen currently talks directly to the shared manager | Pass One | Complete |
| Preset-list presentation state and intent | `BeatPresetsView` in `ContentView.swift` | `BeatPresetsViewModel` | `BeatPresetsViewModel` | Separate screen mixes editor state with preset rules | Pass One and Three | Presentation extraction complete; feature-rule extraction pending |
| Note-value-picker presentation state and intent | `NoteValuePicker` | `NoteValuePickerViewModel` | `NoteValuePickerViewModel` | Screen currently mutates the manager directly | Pass One | Complete |
| Metronome playback state, timing rules, and pattern rules | `MetronomeManager` | `MetronomeManager` behind `MetronomeFeature` | `MetronomeManager` behind `MetronomeFeature` | Existing type mixes several layers and requires incremental separation | Pass Two and Three | Feature boundary complete; internal separation pending |
| Tap-tempo calculation | `MetronomeManager` using `Date()` | `MetronomeManager` with an injected current-date function | `MetronomeManager` | Averaging, clamping, and stale-tap rules are deterministic and directly tested | Pass Three | Complete |
| Tempo adjustment limits | `ContentViewModel` | `MetronomeManager` behind `MetronomeFeature` | `MetronomeManager` | Feature owns the 40–200 BPM adjustment range; gesture sensitivity and haptics remain presentation responsibilities | Pass Three | Implemented; regression tests awaiting Xcode run |
| Available beat-count ranges | `SettingsView` and `GridSettingsViewModel` | `MetronomeManager` behind `MetronomeFeature` | `MetronomeManager` | Preserves the general 1–16 range and the grid's 12-beat triplet cap; controls observe feature-owned ranges | Pass Three | Implemented; regression tests awaiting Xcode run |
| Preset business rules | `MetronomeManager` and `BeatPresetsView` | `MetronomeManager` behind `MetronomeFeature` | `MetronomeManager` | Catalogue, selection, save validation, replacement, deletion, and persistence coordination belong to the existing musical feature | Pass Three | Extraction implemented; regression verification pending |
| Built-in beat preset construction | `BeatPresetsViewModel` | `MetronomeManager` behind `MetronomeFeature` | `MetronomeManager` | The six preset tempos, patterns, accents, and counting modes are now available through the Model | Pass Three | Implemented; regression test awaiting Xcode run |
| Quick preset catalogue and selection | `NoteValuePickerViewModel` | `MetronomeManager` behind `MetronomeFeature` | `MetronomeManager` | Basic, Rock, Jazz, and Fast settings and their application are owned by the feature; haptics and dismissal remain in the ViewModel | Pass Three | Implemented; regression test awaiting Xcode run |
| Preset persistence | `MetronomeManager` using `UserDefaults.standard` | `PresetRepository` supplied to `MetronomeManager` | `PresetRepository` and `UserDefaultsPresetRepository` | Storage is now replaceable without changing feature rules | Pass Three | Complete |
| Audio-session, engine, files, and click scheduling | `MetronomeManager` | `MetronomeAudioPlayer` supplied to `MetronomeManager` | `MetronomeAudioPlayer` and `AVFoundationMetronomeAudioPlayer` | AVFoundation is now isolated below the feature manager | Pass Three | Complete |
| Playback timing and cancellation | `DispatchSourceTimer` inside `MetronomeManager` | `MetronomeTicker` supplied to `MetronomeManager` | Cancellable `Task` inside `SwiftConcurrencyMetronomeTicker` | Preserves the delayed first tick and replaces timing when playback settings change | Pass Four | Complete |
| Tap-count reset and cancellation | `Timer` inside `MetronomeManager` | `CancellableDelayScheduler` supplied to `MetronomeManager` | Cancellable `Task` inside `SwiftConcurrencyDelayScheduler` | Every tap explicitly replaces the pending reset and tests can complete the delay immediately | Pass Four | Complete |
| Metronome visual pulse delay | `DispatchQueue.main.asyncAfter` inside `MetronomeManager` | `CancellableDelayScheduler` supplied to `MetronomeManager` | Cancellable tasks inside `SwiftConcurrencyDelayScheduler` | Preserves overlapping 0.1-second completions while removing GCD from the feature | Pass Four | Complete |
| Haptic creation | SwiftUI Views | Screen ViewModels temporarily | Presentation haptic dependency or feature capability chosen during boundary review | Existing Views instantiate UIKit generators repeatedly | Pass One and Three | Pending |
| Repeating BPM-button timer | `ContentView` | `ContentViewModel` | Cancellable `Task` in `ContentViewModel` | Repeats after a 100ms delay; release, replacement, or ViewModel destruction cancels the interaction | Pass One and Four | Implemented; runtime tests awaiting Xcode run |
| Star-field animation timer and dot mutation | `StarFieldView` | `StarFieldViewModel` | Cancellable `Task` in `StarFieldViewModel` | Maintains approximately 60 updates per second, skips missed frames, and cancels on disappearance or destruction | Pass One and Four | Implemented; runtime tests awaiting Xcode run |
| Production object construction | `MetronomeManager.shared` | `AppBrain.shared` | `AppBrain.live()` | One explicit composition root is required | Pass Two | Complete |
| Siri access to playback | App Intents through `MetronomeManager.shared` | AppBrain facade | `MetronomeFeature` supplied by `AppBrain.shared` | App Intent is another UI entry point into the same feature | Pass Two and Three | Complete |

No architectural production change begins until the behaviour contract has
adequate protection for the responsibility being moved.
