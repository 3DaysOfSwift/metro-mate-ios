# AppBrain Migration Ledger

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
failure handling and preset save-error presentation remain for the next pass.

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
