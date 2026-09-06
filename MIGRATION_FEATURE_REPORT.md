# Migration Feature Behaviour Report

## Current Refinement: Pass Sixteen

The latest iteration removes unused multi-row Model state while preserving the
saved-preset format, separates audio refresh from presentation polling at call
sites, and adds real production-player timeline coverage for rapid tempo edits.
Manual listening and developer approval are still required before closure.

The feature now protects its advertised tempo and beat-count ranges at command
boundaries, and grid-count changes update running audio. Invalid cell indices
are harmless no-ops. Manager state cannot be changed directly by external code;
ViewModels receive only the feature capability and use feature-owned beat queries.
These architecture refinements await manual approval; prior pass approvals
remain historical checkpoints.

## Current Refinement: Pass Fifteen

Closed by explicit developer approval on 7 September 2026 after the developer
reported that the app works well. Implementation commit:
`7afc34fa387fac7b540c7da98d5bcb19b1058ded`. The complete MetronomeTests target passed;
physical-device profiling and measured performance comparisons remain follow-ups.

Audio-progress polling now rejects a result if the pattern changed while the
read was suspended, preventing an obsolete visual beat or blink from being
published. Audio output is unchanged. The concurrency review, resolved
initial-load ordering gap, and remaining queue-growth limits are recorded in the
migration ledger; this does not claim exhaustive concurrency correctness.

The follow-up orders preset edits before initial-load suspension and coalesces
intermediate storage snapshots into the latest complete collection. One write
and one pending snapshot are retained. Rhythm settings use one update worker
and one latest pending configuration. This preserves edits while avoiding
redundant queued work; nonreplaceable commands and caller counts are not capped.

## Current Refinement: Pass Fourteen

As of 7 September 2026, the UI ticker skips missed polls and waits a fresh
interval after an overrun. It no longer replays overdue polls in a burst; the
historical catch-up description below does not describe current behaviour.
Audio remains independently scheduled by the engine. Default, loaded, and random
patterns are assembled locally and published once per array on the Main Actor.
The developer approved the preceding audio implementation and reported all tests
passing; manual approval of these latest refinements remains pending.

## Completion and Scope

Report date: 6 September 2026. Reviewed application commit:
`78ce4fff052b3256861e861b3d6fa16ee1bbbc05`.
This handover adds documentation only to that implementation.

## Post-migration Addendum: Pass Twelve

Subsequent timing-regression work changes the execution described at the original
milestone: AVAudioPlayerNode now loops a rendered rhythm buffer independently of
Main Actor tick delivery. UI polling reads the audio playhead; tap feedback is
separate. StarFieldRenderer performs frame calculation on a presentation actor.
The latest architecture and ledger describe these changes and their remaining
listening checks. The original per-click timing discussion below is historical,
not the current playback implementation. No measured speedup is claimed.

The original completion record below remains a historical milestone. The
subsequent Swift Observation conversion replaces Combine notification forwarding
with @Observable in MetronomeManager, all eight ViewModels, and ThemeManager.
Views retain their dedicated ViewModels using @State. Computed reads through
the feature protocol track the shared state directly, without local copies.
Main Actor isolation, off-main audio/storage, and task lifetimes are unchanged.

SharedFeatureObservationTests now verifies property-specific and cross-screen
tracking, repeated registration, and collection-derived tile state. Added screen
and theme tests cover load failure/retry, local draft state, and palette changes.
Suspended-operation tests use Observation signals instead of Combine publishers.
The ledger records the latest verification and outstanding manual checks.

The AppBrain and Swift Concurrency migration is complete within the agreed
scope. Matthew reported that the migrated app works well and requested final
closure after agreeing to defer additional catch-up diagnostics and profiling.
That general manual approval is not a recorded pass for every device regression
journey. Device audio, Siri, haptics, fallback listening, and measured performance
remain verification work; this is not App Store release certification.

See [the migration ledger](MIGRATION_LEDGER.md),
[the behaviour contract](MIGRATION_BEHAVIOUR_CONTRACT.md), and
[the architecture](ARCHITECTURE.md) for history, requirements, and ownership.

## Final Architecture Audit

- AppBrain constructs one shared live feature graph. Construction does not load
  presets or activate audio. Explicit launch work is an early opportunity, not
  a prerequisite for feature calls.
- All Model support files belong to Features/Metronome. AppBrain itself remains
  outside that folder because application composition is its responsibility.
- Each of the eight View groups has its own ViewModel. Feature references stay
  private to ViewModels; business rules remain in MetronomeManager. Retained
  tasks belong to ViewModels or Model types, not SwiftUI View structs.
- Tests are grouped by feature, screen, presentation, and integration ownership.
- Complete concurrency checking is enabled; Swift 5 language mode remains an
  intentional choice. Combine observation retained at the original milestone
  has since been replaced in Pass Twelve, as described above.
- Observable feature state and lightweight decisions remain Main Actor owned.
  Synchronous audio and storage work use separate serial-executor actors.
  Dispatch-backed executors are intentional adapters for synchronous APIs, not
  leftover callback-driven feature orchestration.
- No unchecked Sendable or detached-task workaround was found in the source
  audit. Cooperative waiting replaces the legacy timer/callback orchestration.
- No new implementation blocker was identified in this closing review. Timing
  equivalence and responsiveness are not proven by compilation or state tests;
  the explicitly deferred checks below remain visible.

## Metronome Playback and Musical Rules

Owner: [MetronomeManager](Metronome/2%20-%20AppBrain/Features/Metronome/MetronomeManager.swift),
accessed through MetronomeFeature. Audio, timing, and preset storage below are
capabilities of this one feature, not additional feature managers.

The feature supports playback, tempo adjustment, subdivisions, beat and accent
editing, tap tempo, built-in and quick presets, randomisation, and reset.
Musical limits and pattern decisions remain in the Model. Screen ViewModels
observe the same feature state without maintaining independent copies.

Repeated starts share pending preparation. Stop invalidates superseded starts
and old queued ticks, then awaits ordered audio cleanup. Playback is shared
application work; leaving a screen does not implicitly stop it. The UI exposes
preparation, playback, and audio failure with retry. Siri awaits playback start
instead of reporting success before preparation completes.

Evidence: MetronomeManagerCharacterisationTests includes
`repeatedPlaybackRequestsKeepPlayingWithoutRestartingTheTicker`,
`playbackRequestReportsAudioFailureAndCanBeRetried`, and
`loadingAPresetWhilePlayingAdvancesExactlyOncePerTick`. Audio concurrency tests
exercise suspended start/stop and in-flight click ordering. The earlier duplicate
tick defect is protected by the one-tick test; migration does not claim identical
execution of every legacy defect. Hardware sound and Siri require manual checks.

## Audio Execution

Owner: MetronomeManager, delegating to AVFoundationMetronomeAudioPlayer.
Session activation, engine construction/setup, file loading, fallback synthesis,
click scheduling, and stopping run on the audio actor's off-main serial executor.
Async feature calls await these operations while UI-observed state remains on
the Main Actor. Audio commands are explicitly ordered through task dependencies.

Fallback buffers are cached after successful preparation, rather than generated
per click. Errors propagate to the feature. An already executing synchronous
system call cannot be preempted; stopping waits for ordered cleanup.

Evidence: MetronomeAudioConcurrencyTests and MetronomeAudioFailureTests cover
ordering, replacement, failure/retry, and off-main executor ownership. They do
not establish speaker output latency or fallback sound quality.

## Preset Persistence

Owner: MetronomeManager, delegating to UserDefaultsPresetRepository.
UserDefaults access and JSON encoding/decoding run on the repository actor's
off-main serial executor. Configuration values enter construction; storage opens
on explicit use. Presets remain local, with no network persistence introduced.

Concurrent requests share a pending load; successful data is retained. Saving
captures the submitted configuration before suspension and waits for loading
before editing the collection. Writes preserve submission order. Older results
cannot replace the visible error state of a newer revision. Committed saves
survive caller cancellation or screen dismissal, but not guaranteed process
termination. Failed writes retain pending edits in memory for retry.

The screen exposes loading, saving, empty content, load failure, save failure,
and retry. Saving the same name replaces that preset; deletion persists the
updated collection. Corrupt stored data follows the documented recovery path.

Evidence: MetronomePresetPersistenceTests, UserDefaultsPresetRepositoryTests,
BeatPresetsViewModelTests, and the characterisation tests cover persistence,
controlled suspension, snapshot/order guarantees, and state exposure. Actual
terminate/relaunch interaction remains a manual regression journey.

## Ticker and Delayed Work

Owner: MetronomeManager, using SwiftConcurrencyMetronomeTicker and
SwiftConcurrencyDelayScheduler. Tasks suspend on clock deadlines rather than
blocking a thread. Replacement and stop cancel old work; revision checks reject
superseded ticks. Each ticker task awaits its callback before continuing.

Planned deadlines continue advancing after a late callback, so overdue ticks may
catch up in a burst. Six real ticker tests verify cancellation, replacement,
destruction, and non-overlapping callbacks. They do not measure audible cadence.
Tap-reset and pulse behaviour also have controlled-scheduler protection.

Additional timestamp diagnostics, deterministic deadline-policy tests, and
device profiling are future improvements. No new late-tick policy was introduced
merely to close this migration.

## Presentation and Application Coordination

AppBrain's explicit launch callback uses async let for independent audio and
preset preparation. AppBrainTests and audio concurrency tests cover this
coordination. Features retain their own readiness and recovery responsibilities.

Screen-specific ViewModels own retained animation, repeated-control, and delayed
dismissal tasks. The star-field calculation remains Main Actor work; profiling
may justify moving expensive calculations later. ThemeManager supplies the
selected AppColourTheme. ViewModel, theme, and shared-observation tests protect
presentation state and cross-screen consistency.

## Verification and Follow-up

The final MetronomeTests suite passed on the iPhone Air iOS 26.2 simulator with
the Metronome scheme, Debug configuration, and complete concurrency checking.
This excludes MetronomeUITests. Earlier full builds and focused strict
typechecking passed as recorded in the ledger. No pre-change performance profile
was captured, and no speedup, reduced IPA size, or real-time guarantee is claimed.

Deferred work: representative-device profiling during startup/animation/playback;
bundled and fallback audio listening; catch-up cadence measurements; hardware
mute-switch/haptics and Siri checks. General user approval does not substitute
for these specific checks. Preserve these limits when presenting this project
as a teaching example.
