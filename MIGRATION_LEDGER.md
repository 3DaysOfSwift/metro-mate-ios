# AppBrain Migration Ledger

## Pass Ten: Off-Main Feature Execution — In Progress

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
verification; this is not a completed responsiveness pass. Existing app-icon
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

Remaining checkpoints:

1. Capture a combined cold-start, star-field animation, and playback baseline
   using Instruments on a representative device. Include missing audio files
   and preset loading/saving. No latency or frame-time measurements exist yet.
2. Give the existing audio implementation one serial off-main execution owner
   for its mutable engine, files, and buffers. Respect AVFoundation's execution
   requirements; bridge unavoidable blocking setup without blocking the
   cooperative pool. Expose awaited preparation/start results and prevent a
   cancelled or superseded start from restarting playback. Keep scheduling
   ordered with stop and tempo changes; do not launch detached work per beat.
3. Once audio preparation is async, preserve independent audio and persistence
   startup. Audio still prepares synchronously before the awaited preset load.
4. Test the real ticker's cancellation, replacement, and missed deadlines;
   agree and document late-tick behaviour before changing its current catch-up
   policy. Compare timing under animation load.
5. Repeat profiling, strict checking, and regressions. Move costly animation
   calculations off-main only if measurements warrant it, publishing completed
   frames without stale results. Do not add Task.yield merely as a showcase.

Audio preparation remains synchronous. Its off-main conversion, real ticker
tests, fallback playback verification, and performance gates remain open.

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
