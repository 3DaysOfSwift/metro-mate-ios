# Migration Behaviour Contract

## Closing Record

The migration was closed by agreement on 6 September 2026. The table below
preserves the original baseline assessment; its Pending labels are not a
current test-run summary. Current implementation, automated evidence, general
user approval, and explicitly unverified manual checks are summarised in
[MIGRATION_FEATURE_REPORT.md](MIGRATION_FEATURE_REPORT.md). No unperformed
manual journey has been retrospectively marked as passed.

## Baseline

- Original repository: `alexfriedl/metro-mate-ios`
- Original commit: `57670a1e23a2fb4bb3d55cf297b67528695fc849`
- Migration branch: `migration/appmodel-swift-concurrency`
- Baseline environment: Xcode 26.2, iPhone Air simulator running iOS 26.2
- Baseline result: the complete `Metronome` scheme test action passed on 6 September 2026
- Existing automated protection: one empty unit test, one launch-only UI test, four launch configurations, and one launch-performance test

The existing tests prove that the original application builds and launches in
the baseline environment. They do not protect the metronome's product rules,
audio timing, persistence, or interactive journeys. Requirements below are
therefore marked inferred or unprotected until characterisation tests or manual
regression evidence establish them.

## Behaviour Requirements

| ID | Plain-English requirement | Legacy evidence | Evidence status | Baseline | Replacement protection | Post-migration result | Manual regression | Difference and approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BEH-001 | The application launches into a usable metronome screen. | Existing UI launch tests and successful simulator launch | Confirmed | Pass | Existing UI launch tests | Pending | Pending | None |
| BEH-002 | Pressing Play starts at the first beat, produces clicks at the selected tempo and subdivision, and advances the visible beat indicator. | `MetronomeManager.start()`, `tick()`, and `playClick()` | Unprotected | Observed launch only | Pending | Pending | Pending | None |
| BEH-003 | Pressing Pause stops future beats and resets the visible playing state. | `MetronomeManager.stop()` | Inferred | Not recorded | Pending | Pending | Pending | None |
| BEH-004 | BPM remains within 40–200 whether changed by buttons, dragging, or tap tempo. | `ContentView` controls and `tapTempo()` clamping | Inferred | Not recorded | Pending | Pending | Pending | None |
| BEH-005 | Changing BPM while playing replaces the timer and subsequent beats use the new interval without starting another playback session. | `updateBPM(_:)` | Unprotected | Not recorded | Pending | Pending | Pending | None |
| BEH-006 | Selecting a note value updates its beat count, counting display, default pattern, title, and active playback interval. | `updateNoteValue(_:)` | Unprotected | Not recorded | `MetronomeManagerCharacterisationTests` protects state changes; active timing remains pending | Pending | Pending | None |
| BEH-007 | Editing an active beat or accent updates the pattern and identifies it as a custom beat. | `toggleGridCell` and `toggleAccentCell` | Confirmed | Characterisation test | `editingThePatternMarksItAsCustom()` | Pending | Pending | None |
| BEH-008 | Tap tempo calculates BPM from recent taps, uses at most eight recent taps, ignores taps older than three seconds, and leaves the calculated BPM visible after the tap counter clears. | `tapTempo()` | Unprotected | Not recorded | Pending | Pending | Pending | None |
| BEH-009 | Randomising creates a playable pattern, always activates and accents its first beat, retains the current BPM, and labels the result Random Beat. | `randomizeBeat()` | Confirmed | Characterisation test | `randomBeatPreservesTempoAndAlwaysStartsWithAnAccentedBeat()` | Pending | Pending | None |
| BEH-010 | Reset restores the Eighth pattern at 80 BPM with eight beats and the default counting mode. | `resetToBasicBeat()` | Confirmed | Characterisation test | `resetRestoresTheExistingBasicBeat()` | Pending | Pending | None |
| BEH-011 | Saving a named preset replaces an existing preset with the same name and persists the result locally across application termination and relaunch. | `saveBeatPreset`, `persistPresets`, and README | Unprotected | Replacement-by-name characterised; relaunch persistence not recorded | `savingTheSameNameReplacesTheExistingPreset()` plus pending integration test | Pending | Pending | None |
| BEH-012 | Loading a preset restores its tempo, note value, beat count, counting mode, beat pattern, accents, and name. | `loadBeatPreset(_:)` | Confirmed | Characterisation test | `loadingPresetRestoresAllPersistedConfiguration()` | Pending | Pending | None |
| BEH-013 | Deleting a preset removes it from persistent storage and restores the Eighth title when the deleted preset was selected. | `deleteBeatPreset(_:)` | Unprotected | In-memory deletion and title characterised; relaunch persistence not recorded | `deletingTheSelectedPresetRestoresTheExistingTitle()` plus pending integration test | Pending | Pending | None |
| BEH-014 | Corrupt or incompatible preset data does not crash launch and is removed from local storage. | `restorePresets()` | Inferred | Not recorded | Pending | Pending | Pending | None |
| BEH-015 | Accent beats use the accent sound and ordinary active beats use the normal sound, with generated tones used when bundled audio cannot be loaded. | `playClick()` and `createClickBuffer(accent:)` | Unprotected | Not recorded | Pending | Pending | Pending | None |
| BEH-016 | Metronome audio remains audible when the device mute switch is enabled. | Audio-session playback category and README | Inferred | Simulator cannot establish | Pending | Pending | Real device required | None |
| BEH-017 | Starting the app through Siri can start playback, and the BPM shortcut applies the requested supported tempo before playback begins. | App Intents implementations | Unprotected | Not recorded | Pending | Pending | Real device recommended | None |
| BEH-018 | Presets remain only on the device and the application performs no network request. | README, Privacy policy, and UserDefaults implementation | Confirmed | Source inspection | Pending | Pending | Pending | None |
| BEH-019 | Haptic feedback accompanies the existing interactive controls on supported hardware. | SwiftUI button actions | Unprotected | Simulator cannot establish | Pending | Pending | Real device required | None |
| BEH-020 | Loading a preset while playback is active must continue at the correct interval and advance one beat per timer event. | Intended metronome behaviour versus two consecutive `tick()` calls in `loadBeatPreset(_:)` | Conflicting | Investigation required | Pending | Pending | Pending | Possible existing defect; no decision yet |

## Required Manual Regression Journeys

### Test Locations after Pass Eight

MetronomeManagerCharacterisationTests and NoteValueTests now live under
AppModel tests/Features/Metronome; their names and test methods are unchanged.
Real storage tests live in that feature's Preset Storage folder. Screen tests
are named after their individual ViewModels, and cross-screen observation is
in Integration tests/SharedFeatureObservationTests. Test regrouping does not
change the behavioural requirements or constitute a new passing test run.

1. Launch, start, observe several measures, and stop playback.
2. Change BPM while stopped and while playing using every control.
3. Select every note value and verify its visual counting and audible cadence.
4. Toggle beats and accents, then play the resulting custom pattern.
5. Use tap tempo slowly, quickly, and after a pause longer than three seconds.
6. Randomise and reset while stopped and while playing.
7. Save, replace, load, delete, terminate, and relaunch with presets.
8. Exercise Siri start and start-at-BPM shortcuts.
9. Verify mute-switch audio and haptics on a real device.

Record the tester, date, build, environment, outcome, and linked defect for each
journey after the architecture milestone and again after concurrency migration.
