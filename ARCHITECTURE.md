# Metro Mate Architecture

## Ordered Edits and Coalesced Work

Preset commands capture their input before suspension and apply edits in arrival
order, including while the initial load is pending. Each edit synchronously
submits its resulting collection to one persistence worker. The worker keeps
one active write and one latest pending snapshot, so intermediate disk writes
may be coalesced without discarding edits. Callers await the worker; cancellation
of a screen does not cancel committed work. Latest failures remain visible for
retry.

Rhythm configuration similarly uses one update worker and one latest pending
pattern. Stop invalidates the worker and clears pending settings. Already
executing synchronous audio work finishes before ordered cleanup. Clicks and
start/stop commands are not silently dropped or coalesced with rhythm edits.

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
Cached click buffers are scheduled at absolute sample positions across a fixed
voice pool. A silent clock node gives every voice the same continuous timeline.
The audio actor owns one cancellable refill task (20 ms polling, an initial
100 ms look-ahead window, and 10 ms scheduling lead). Tempo and pattern requests
replace the pending configuration; committed beats are not stopped or delayed.
There is no time-stretching. Generation checks protect restarted playback from
obsolete refills. Late refills skip expired beats and report the underrun;
other refill failures stop playback and reach the feature's error state.
These scheduling margins still require device measurements and listening checks.
The main-actor ticker only polls the audio playhead for display; it never triggers
an audible beat. Tap feedback uses a separate node. Tempo and pattern edits pass
through ordered audio commands. Voices preserve overlapping click tails, and
progress reports the committed beat index rather than deriving it from the
latest requested measure size. Controls still display requested configuration
while already committed audio finishes.
AppBrain starts audio preparation and preset loading as independent child tasks.

StarFieldRenderer is a presentation actor that calculates dot frames outside
the Main Actor. StarFieldViewModel retains its single animation task, submits
value inputs, and publishes completed frames. Resize revisions and cancellation
prevent stale publication. SwiftUI drawing still belongs to presentation.

Each ViewModel receives a narrow MetronomeFeature dependency directly through
its initializer and keeps that reference private. Omitting that dependency selects AppBrain.shared.metronome
inside the Main Actor initializer; callers no longer inject the entire AppBrain.
Feature state has private setters, and tap timestamps are private bookkeeping.
The musical beat pattern is one flat sequence. Grid rows belong to presentation,
not duplicated Model state; toggleBeat(at:) takes a musical beat index. Saved
presets retain their existing flat-array representation.
Beat activity and accent queries belong to the feature; presentation retains
highlighting and pulse styling. Commands enforce tempo/count boundaries and
grid count changes refresh active audio as well as observable state.
Audio refresh and presentation polling are explicit separate operations at their
call sites; startPlaybackProgressPolling does not reconfigure audio.

Views read screen-facing properties and call ViewModel actions; they cannot reach through a ViewModel
into the feature API. Musical limits, including the tempo range, belong to the
feature. ViewModels expose those limits without redefining them.

MetronomeManager, each dedicated ViewModel, and ThemeManager use @Observable.
SwiftUI tracks property reads through computed ViewModel properties into the
shared feature, including through MetronomeFeature. No publisher forwarding or
copied feature state is needed. Observable state remains Main Actor isolated;
Observation does not change execution ownership or provide thread safety.

Each screen owns its viewModel using @State. Existing bindings project through
that state or explicitly forward a feature command. Initializers retain inputs
without starting work: @State preserves the installed object for a View identity,
but initial-value expressions may run again when View values are constructed.
Task handles and internal scheduling bookkeeping use @ObservationIgnored;
their cancellation and lifetime responsibilities are unchanged. Observation
tests register one-shot tracking and read final values after mutation.

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
│       ├── StarField/       StarFieldView.swift, StarFieldViewModel.swift, StarFieldRenderer.swift
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
│       │   ├── MetronomePlaybackPattern.swift
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
│       ├── Audio/
│       │   ├── MetronomeAudioFailureTests.swift
│       │   ├── MetronomePlaybackPatternTests.swift
│       │   └── MetronomeAudioConcurrencyTests.swift
│       ├── Data Types/NoteValueTests.swift
│       ├── Preset Storage/
│       │   ├── MetronomePresetPersistenceTests.swift
│       │   └── UserDefaultsPresetRepositoryTests.swift
│       └── Timing/SwiftConcurrencyMetronomeTickerTests.swift
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
