# Migration Review

## Status

The architectural restructuring and explicit GCD/timer replacement are implemented.
This is not yet a claim of runtime equivalence or completed regression testing.

## Architecture Findings

- AppBrain composes shared features; screen ViewModels keep feature references private.
- Each custom View has a dedicated ViewModel. Private rendering functions keep
  picker controls within their owning screen rather than passing actions between Views.
- Musical rules and tempo limits are feature-owned. Rendering, gestures, haptics,
  theme selection, and animation remain in the UI layer.
- Theme values are centralised; the environment carries a palette, not the Model.
- Stored tasks have explicit owners and cancellation paths.
- Combine remains intentionally in place. An Observation conversion is not
  required to complete the GCD migration and should be a separately verified pass.

## Remaining Risks and Evidence

1. The playback ticker advances deadlines one interval at a time. If the main
   actor stalls, deadlines can be in the past and ticks can catch up rapidly.
   Compare with the original build under load before deciding whether to skip
   missed beats or change audio scheduling. Do not silently change this policy.
2. Preset loading while playing now schedules one tick per event. The original
   behaviour contract recorded a double-tick defect; explicitly verify and accept
   this correction rather than describing it as exact preservation.
3. Audio and storage errors are now visible, and pulse completions are cancelled
   on stop. These are deliberate failure/lifetime changes requiring regression.
4. UserDefaults corruption still removes the preset key, preserving the recorded
   legacy policy. This is not recoverable storage; do not describe Retry as recovery
   of the corrupted presets.

## Added Storage Protection

UserDefaultsPresetRepositoryTests uses unique, disposable test suites, never the
live app's defaults. It checks field round-trip, repository recreation, deletion,
and corruption handling. Repository recreation is not a process-termination test.
Run these tests in Xcode; this session cannot connect to CoreSimulator.

## Final Verification Gate

Run the full scheme tests and all journeys in MIGRATION_BEHAVIOUR_CONTRACT.md.
Record build/commit, device or simulator, tester, result, and any defect.
Especially verify live preset loading, long presses, sheet dismissal, Siri,
terminate/relaunch persistence, and real-device mute-switch audio and haptics.
Compare audible cadence with the baseline under load before marking migration
complete. No further restructuring is necessary solely to make the folder tree
look more elaborate.
