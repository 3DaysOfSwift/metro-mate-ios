# Metro Mate Architecture

## Responsibilities

SwiftUI Views describe each screen. Each screen owns its dedicated ViewModel,
which manages presentation state and user interactions. ViewModels obtain the
metronome feature from AppBrain. MetronomeManager owns musical rules and delegates
audio, timing, and preset storage to the dependencies constructed by AppBrain.live().

PresetRepository exposes asynchronous loading and saving. Its live implementation
is an actor using a serial off-main executor for synchronous UserDefaults and
JSON operations. MetronomeManager retains Main Actor ownership of observable
state, shares in-flight loads, and orders writes so older snapshots cannot
overwrite newer edits. Committed writes outlive the presenting screen.
AVFoundationMetronomeAudioPlayer also owns a serial off-main executor. Its engine
and player are created on first explicit audio use on that executor, not during
AppBrain construction. The feature awaits audio commands in submission order,
invalidates superseded starts and queued ticks, and publishes a starting state.
The ticker awaits each click; it does not launch detached work per beat.
AppBrain starts audio preparation and preset loading as independent child tasks.

Each ViewModel keeps its feature reference private. Views read screen-facing
properties and call ViewModel actions; they cannot reach through a ViewModel
into the feature API. Musical limits, including the tempo range, belong to the
feature. ViewModels expose those limits without redefining them.

The current observation mechanism remains Combine: a ViewModel forwards the
feature's objectWillChange notification using a weak capture, and its computed
properties read the shared feature state. It does not copy feature state.
Notifications precede mutation; subscribers must not treat them as updated values.
An Observation conversion is a separate change, not part of this boundary pass.

## Folder Structure

```text
Metronome/
├── 1 - View/
│   ├── App.swift
│   ├── App Intents/AppIntents.swift
│   ├── SwiftUI Extensions/ColorExtension.swift
│   ├── Theme/ AppColourTheme.swift, ThemeManager.swift
│   └── Views/
│       ├── Content/         ContentView.swift, ContentViewModel.swift
│       ├── Grid/            GridView.swift, GridViewModel.swift
│       ├── Settings/        SettingsView.swift, SettingsViewModel.swift
│       ├── GridSettings/    GridSettingsView.swift, GridSettingsViewModel.swift
│       ├── BeatPresets/     BeatPresetsView.swift, BeatPresetsViewModel.swift
│       ├── BeatTile/        BeatTile.swift, BeatTileViewModel.swift
│       ├── StarField/       StarFieldView.swift, StarFieldViewModel.swift
│       └── NoteValuePicker/ NoteValuePicker.swift, NoteValuePickerViewModel.swift
├── 2 - AppBrain/
│   ├── AppBrain.swift
│   └── Features/Metronome/
│       ├── MetronomeFeature.swift
│       ├── MetronomeManager.swift
│       ├── Data Types/
│       │   ├── NoteValue.swift
│       │   ├── GridDisplayMode.swift
│       │   ├── BeatPreset.swift
│       │   └── QuickPreset.swift
│       ├── Audio/
│       │   ├── MetronomeAudioPlayer.swift
│       │   └── AVFoundationMetronomeAudioPlayer.swift
│       ├── Preset Storage/
│       │   ├── PresetRepository.swift
│       │   └── UserDefaultsPresetRepository.swift
│       └── Timing/
│           ├── MetronomeTicker.swift
│           ├── SwiftConcurrencyMetronomeTicker.swift
│           ├── CancellableDelayScheduler.swift
│           └── SwiftConcurrencyDelayScheduler.swift
└── 3 - App Resources/
    ├── Assets.xcassets
    ├── Metronome.entitlements
    └── Audio/
        ├── accent_click.wav
        ├── normal_click.wav
        ├── accent_click.wav.asd
        └── normal_click.wav.asd

MetronomeTests/
├── AppBrain tests/
│   ├── AppBrainTests.swift
│   └── Features/Metronome/
│       ├── MetronomeManagerCharacterisationTests.swift
│       ├── Audio/MetronomeAudioFailureTests.swift
│       ├── Data Types/NoteValueTests.swift
│       └── Preset Storage/
│           ├── MetronomePresetPersistenceTests.swift
│           └── UserDefaultsPresetRepositoryTests.swift
├── View model tests/
│   ├── ContentViewModelTests.swift
│   ├── SettingsViewModelTests.swift
│   ├── GridSettingsViewModelTests.swift
│   ├── BeatPresetsViewModelTests.swift
│   ├── NoteValuePickerViewModelTests.swift
│   ├── GridViewModelTests.swift
│   ├── BeatTileViewModelTests.swift
│   └── StarFieldViewModelTests.swift
├── Integration tests/SharedFeatureObservationTests.swift
├── Presentation tests/ThemeManagerTests.swift
└── Test Doubles/
```

Xcode synchronises these folders with the app and test targets. Resource filenames
remain unchanged; the signing configurations reference the relocated entitlements.
The audio analysis sidecar files are preserved from the original project.

## Colour Theme

AppColourTheme keeps colour values together. The App owns one ThemeManager and
supplies its selected palette as a SwiftUI environment value to all screens and
their presentation subviews. No feature manager is constructed by the environment.
Classic preserves the original colours. Midnight is an alternate development
palette, not a new customer setting. Theme selection is in-memory only.
Views retain their existing opacity and layout choices.

## Remaining Migration Work

Tests are grouped by the boundary they exercise. Each screen has a focused
ViewModel suite; cross-screen tests remain explicitly integration tests rather
than being mistaken for one screen's unit tests. Feature and repository tests
live under Metronome. Test doubles remain shared because both feature and UI
tests use them; they are not duplicated into each suite.

Note-picker buttons are private rendering functions within their owning screen,
not separate Views accepting action closures. The picker ViewModel owns selection
and dismissal, and supplies the decorative dot counts. BeatTile remains a separate
View with its own ViewModel because each tile has distinct pressed state and beat
identity. Its beat-index input identifies the item; it does not inject a manager
or a parent action.

This layout makes ownership visible, but does not mean the migration is complete.
See MIGRATION_LEDGER.md for pending responsibility reviews and
MIGRATION_BEHAVIOUR_CONTRACT.md for the regression journeys.
