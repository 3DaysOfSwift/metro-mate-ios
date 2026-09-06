# AppBrain Migration Ledger

## Starting Architecture

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
| Metronome playback state, timing rules, and pattern rules | `MetronomeManager` | AppBrain staging | `MetronomeManager` behind `MetronomeFeature` | Existing type mixes several layers and requires incremental separation | Pass Two and Three | Pending |
| Tap-tempo calculation | `MetronomeManager` | AppBrain staging | `MetronomeManager` | Business rule needs a controllable clock and direct tests | Pass Three | Pending |
| Preset business rules | `MetronomeManager` and `BeatPresetsView` | AppBrain staging | `PresetManager` only if separation provides a clear maintenance benefit; otherwise `MetronomeManager` | Final feature boundary requires evaluation against KISS | Pass Three | Pending |
| Preset persistence | `MetronomeManager` using `UserDefaults.standard` | AppBrain staging | `PresetRepository` and `UserDefaultsPresetRepository` | External storage is embedded in the feature object | Pass Three | Pending |
| Audio-session, engine, files, and click scheduling | `MetronomeManager` | AppBrain staging | Audio implementation behind a narrow playback contract | Device API details prevent isolated feature tests | Pass Three | Pending |
| Haptic creation | SwiftUI Views | Screen ViewModels temporarily | Presentation haptic dependency or feature capability chosen during boundary review | Existing Views instantiate UIKit generators repeatedly | Pass One and Three | Pending |
| Repeating BPM-button timer | `ContentView` | `ContentViewModel` | `ContentViewModel` | This is tracked interaction state and must not remain stored in a View | Pass One | Complete |
| Star-field animation timer and dot mutation | `StarFieldView` | `StarFieldViewModel` | `StarFieldViewModel` | The View stores and updates tracked animation work | Pass One | Complete |
| Production object construction | `MetronomeManager.shared` | `AppBrain.shared` | `AppBrain.live()` | One explicit composition root is required | Pass Two | Complete |
| Siri access to playback | App Intents through `MetronomeManager.shared` | AppBrain facade | `MetronomeFeature` supplied by `AppBrain.shared` | App Intent is another UI entry point into the same feature | Pass Two and Three | AppBrain routing complete; feature API pending |

No architectural production change begins until the behaviour contract has
adequate protection for the responsibility being moved.
