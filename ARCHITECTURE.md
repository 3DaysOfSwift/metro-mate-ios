# Metro Mate Architecture

## Responsibilities

SwiftUI Views describe each screen. Each screen owns its dedicated ViewModel,
which manages presentation state and user interactions. ViewModels obtain the
metronome feature from AppBrain. MetronomeManager owns musical rules and delegates
audio, timing, and preset storage to the dependencies constructed by AppBrain.live().

## Folder Structure

```text
Metronome/
├── 1 - View/
│   ├── App.swift
│   ├── App Intents/AppIntents.swift
│   ├── SwiftUI Extensions/ColorExtension.swift
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
│   ├── Features/Metronome/
│   │   ├── MetronomeFeature.swift
│   │   ├── MetronomeManager.swift
│   │   └── Data Types/
│   │       ├── NoteValue.swift
│   │       ├── GridDisplayMode.swift
│   │       ├── BeatPreset.swift
│   │       └── QuickPreset.swift
│   ├── Audio/
│   │   ├── MetronomeAudioPlayer.swift
│   │   └── AVFoundationMetronomeAudioPlayer.swift
│   ├── Preset Storage/
│   │   ├── PresetRepository.swift
│   │   └── UserDefaultsPresetRepository.swift
│   └── Timing/
│       ├── MetronomeTicker.swift
│       ├── SwiftConcurrencyMetronomeTicker.swift
│       ├── CancellableDelayScheduler.swift
│       └── SwiftConcurrencyDelayScheduler.swift
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
├── View model tests/
└── Test Doubles/
```

Xcode synchronises these folders with the app and test targets. Resource filenames
remain unchanged; the signing configurations reference the relocated entitlements.
The audio analysis sidecar files are preserved from the original project.

## Migration Status

This layout makes ownership visible, but does not mean the migration is complete.
See MIGRATION_LEDGER.md for pending responsibility reviews and
MIGRATION_BEHAVIOUR_CONTRACT.md for the regression journeys.
