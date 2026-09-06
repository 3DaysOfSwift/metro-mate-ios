import Foundation
import Observation

@MainActor
@Observable
final class MetronomeManager: MetronomeFeature {
    var isPlaying = false
    private(set) var isStartingPlayback = false
    @ObservationIgnored private var playbackStartTask: Task<Void, Error>?
    @ObservationIgnored private var lastAudioOperation: Task<Void, Error>?
    @ObservationIgnored private var playbackUpdateTask: Task<Void, Never>?
    @ObservationIgnored private var patternRevision = 0
    @ObservationIgnored private var lastPlaybackStep: Int?
    @ObservationIgnored private var playbackRevision = 0
    @ObservationIgnored private var tickerRevision = 0
    var bpm: Double = 60
    var beatsPerMeasure = 8
    var currentBeat = -1
    var shouldBlink = false
    var gridPattern: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 4)
    var accentPattern: [Bool] = Array(repeating: false, count: 16)
    var gridSize = 4
    var noteValue: NoteValue = .eighth
    var gridDisplayMode: GridDisplayMode = .andCounting
    var currentBeatName: String = "Eighth"
    var savedBeats: [BeatPreset] = []
    var tapTimes: [Date] = []
    var tapCount: Int = 0
    private let maxTapCount = 8
    let beatCountRange = 1...16
    let tempoRange: ClosedRange<Double> = 40...200
    var gridBeatCountRange: ClosedRange<Int> {
        1...(noteValue.isTriplet ? 12 : 16)
    }
    let quickPresets = [
        QuickPreset(title: "Basic", bpm: 120, noteValue: .quarter),
        QuickPreset(title: "Rock", bpm: 110, noteValue: .eighth),
        QuickPreset(title: "Jazz", bpm: 140, noteValue: .quarterTriplet),
        QuickPreset(title: "Fast", bpm: 160, noteValue: .sixteenth)
    ]
    
    private let presetRepository: any PresetRepository
    private let audioPlayer: any MetronomeAudioPlayer
    private let ticker: any MetronomeTicker
    private let tapResetScheduler: any CancellableDelayScheduler
    private let blinkScheduler: any CancellableDelayScheduler
    /// Supplies the current date so time-based rules can be tested without waiting for real time.
    private let currentDate: () -> Date
    @ObservationIgnored private var hasLoadedPresets = false
    @ObservationIgnored private var presetLoadTask: Task<Void, Never>?
    @ObservationIgnored private var presetSaveTask: Task<Void, Never>?
    @ObservationIgnored private var presetSaveRevision = 0
    private(set) var isLoadingPresets = false
    private(set) var isSavingPresets = false
    private(set) var presetLoadError: String?
    private(set) var presetSaveError: String?
    private(set) var audioError: String?

    init(
        presetRepository: any PresetRepository,
        audioPlayer: any MetronomeAudioPlayer,
        ticker: any MetronomeTicker,
        tapResetScheduler: any CancellableDelayScheduler,
        blinkScheduler: any CancellableDelayScheduler,
        currentDate: @escaping () -> Date
    ) {
        self.presetRepository = presetRepository
        self.audioPlayer = audioPlayer
        self.ticker = ticker
        self.tapResetScheduler = tapResetScheduler
        self.blinkScheduler = blinkScheduler
        self.currentDate = currentDate
        setupDefaultPattern()
    }

    /// Warms the audio system without starting metronome playback.
    func prepareAudio() async {
        let operation = enqueueAudioOperation {
            do {
                try await self.audioPlayer.prepare()
                self.audioError = nil
            } catch {
                self.audioError = error.localizedDescription
                throw error
            }
        }
        _ = await operation.result
    }

    /// Actor isolation alone does not promise submission order. Each audio
    /// command awaits its predecessor, including Stop after an in-flight click.
    private func enqueueAudioOperation(
        _ operation: @escaping @MainActor () async throws -> Void
    ) -> Task<Void, Error> {
        let previous = lastAudioOperation
        let task = Task {
            _ = await previous?.result
            try await operation()
        }
        lastAudioOperation = task
        return task
    }
    
    private func setupDefaultPattern() {
        // Build locally so Observation sees one publication per completed array.
        var gridPattern = self.gridPattern
        var accentPattern = self.accentPattern
        // Clear all patterns first
        for i in 0..<gridPattern.count {
            for j in 0..<gridPattern[i].count {
                gridPattern[i][j] = false
            }
        }
        
        // Clear accent pattern
        for i in 0..<accentPattern.count {
            accentPattern[i] = false
        }
        
        // Set all beats active for current beatsPerMeasure
        for i in 0..<beatsPerMeasure {
            gridPattern[0][i] = true
        }
        
        // Set accents on beats 1,2,3,4 for all default patterns
        switch noteValue {
        case .quarter:
            // Quarter: accent on beats 0,1,2,3 (positions 1,2,3,4)
            for i in 0..<min(4, beatsPerMeasure) {
                accentPattern[i] = true
            }
        case .eighth:
            // Eighth: accent on beats 0,2,4,6 (positions 1,2,3,4)
            let accentPositions = [0, 2, 4, 6] // beats 1,2,3,4
            for position in accentPositions {
                if position < beatsPerMeasure {
                    accentPattern[position] = true
                }
            }
        case .sixteenth:
            // Sixteenth: accent on beats 0,4,8,12 (positions 1,2,3,4)
            let accentPositions = [0, 4, 8, 12] // beats 1,2,3,4
            for position in accentPositions {
                if position < beatsPerMeasure {
                    accentPattern[position] = true
                }
            }
        case .quarterTriplet:
            // Quarter triplet: accent on beats 0,1,2 (positions 1,2,3)
            for i in 0..<min(3, beatsPerMeasure) {
                accentPattern[i] = true
            }
        case .eighthTriplet:
            // Eighth triplet: accent on beats 0,3 (positions 1,2)
            for i in stride(from: 0, to: min(6, beatsPerMeasure), by: 3) {
                accentPattern[i] = true
            }
        case .sixteenthTriplet:
            // Sixteenth triplet: accent on beats 0,3,6,9 (positions 1,2,3,4)
            for i in stride(from: 0, to: min(12, beatsPerMeasure), by: 3) {
                accentPattern[i] = true
            }
        }
        self.gridPattern = gridPattern
        self.accentPattern = accentPattern
    }
    
    func togglePlayback() async {
        if isPlaying || isStartingPlayback {
            await stop()
        } else {
            do {
                try await startPlayback()
            } catch {
                // startPlayback publishes failures; a superseded start is silent.
            }
        }
    }
    
    /// Starts only when stopped. Repeated requests must never toggle playback off.
    func startPlayback() async throws {
        guard !isPlaying else { return }
        if let playbackStartTask {
            try await playbackStartTask.value
            return
        }
        playbackRevision += 1
        let revision = playbackRevision
        isStartingPlayback = true
        let task = Task {
            defer {
                if revision == playbackRevision {
                    isStartingPlayback = false
                    playbackStartTask = nil
                }
            }
            try Task.checkCancellation()
            var scheduledPattern: MetronomePlaybackPattern?
            let operation = enqueueAudioOperation {
                guard revision == self.playbackRevision else { throw CancellationError() }
                do {
                    try await self.audioPlayer.startIfNeeded()
                    guard revision == self.playbackRevision else { throw CancellationError() }
                    let pattern = self.playbackPattern(restart: true)
                    scheduledPattern = pattern
                    try await self.audioPlayer.schedulePlayback(pattern, initialDelay: 0.01)
                    if revision == self.playbackRevision { self.audioError = nil }
                } catch {
                    if revision == self.playbackRevision {
                        self.audioError = error.localizedDescription
                    }
                    throw error
                }
            }
            try await operation.value
            try Task.checkCancellation()
            guard revision == playbackRevision else { throw CancellationError() }
            isPlaying = true
            currentBeat = -1
            startTicker(after: .milliseconds(10))
            // Settings may change while the audio executor is building the loop.
            if scheduledPattern != playbackPattern(restart: true) { refreshAudioPattern() }
        }
        playbackStartTask = task
        try await task.value
    }

    /// Applies the requested tempo before starting, or retimes existing playback.
    func startPlayback(atBPM bpm: Double) async throws {
        updateBPM(bpm)
        try await startPlayback()
    }

    private func stop() async {
        playbackRevision += 1
        tickerRevision += 1
        playbackStartTask?.cancel()
        playbackUpdateTask?.cancel()
        playbackUpdateTask = nil
        playbackStartTask = nil
        isStartingPlayback = false
        isPlaying = false
        ticker.stop()
        blinkScheduler.cancel()
        currentBeat = -1
        shouldBlink = false
        lastPlaybackStep = nil
        
        let operation = enqueueAudioOperation { await self.audioPlayer.stop() }
        _ = await operation.result
    }
    
    private func tick(revision: Int) async {
        guard isPlaying, revision == tickerRevision, !Task.isCancelled else { return }
        // UI follows the audio timeline; a late UI tick cannot delay a click.
        let beat = await audioPlayer.playbackBeat()
        guard isPlaying, revision == tickerRevision, !Task.isCancelled,
              let beat, beat != lastPlaybackStep else { return }
        lastPlaybackStep = beat
        currentBeat = beat % beatsPerMeasure
        triggerVisualBlink()
    }
    
    private func playSound(accented: Bool) async {
        let revision = playbackRevision
        let operation = enqueueAudioOperation {
            guard revision == self.playbackRevision else { return }
            do {
                try await self.audioPlayer.playClick(accented: accented)
                if revision == self.playbackRevision { self.audioError = nil }
            } catch {
                if revision == self.playbackRevision {
                    self.audioError = error.localizedDescription
                }
                throw error
            }
        }
        do {
            try await operation.value
        } catch {
            guard revision == playbackRevision else { return }
            await stop()
        }
    }
    
    
    private func triggerVisualBlink() {
        shouldBlink = true
        blinkScheduler.schedule(after: .milliseconds(100)) { [weak self] in
            self?.shouldBlink = false
        }
    }
    
    func updateBPM(_ newBPM: Double) {
        bpm = newBPM
        
        if isPlaying {
            restartTicker()
        }
    }

    func adjustedBPM(by amount: Double) -> Double {
        max(tempoRange.lowerBound, min(tempoRange.upperBound, bpm + amount))
    }

    func adjustBPM(by amount: Double) {
        updateBPM(adjustedBPM(by: amount))
    }
    
    func updateNoteValue(_ newNoteValue: NoteValue) {
        noteValue = newNoteValue
        beatsPerMeasure = newNoteValue.beatsPerMeasure
        
        // Set appropriate display mode based on note value
        switch newNoteValue {
        case .quarter, .quarterTriplet:
            gridDisplayMode = .andCounting
        case .eighth, .eighthTriplet:
            gridDisplayMode = .andCounting
        case .sixteenth, .sixteenthTriplet:
            gridDisplayMode = .subdivisionCounting
        }
        
        // Set beat name based on note value (only if not custom/random)
        if currentBeatName != "Custom Beat" && currentBeatName != "Random Beat" {
            switch newNoteValue {
            case .quarter:
                currentBeatName = "Quarter"
            case .eighth:
                currentBeatName = "Eighth"
            case .sixteenth:
                currentBeatName = "Sixteenth"
            case .quarterTriplet:
                currentBeatName = "Quarter Triplet"
            case .eighthTriplet:
                currentBeatName = "Eighth Triplet"
            case .sixteenthTriplet:
                currentBeatName = "Sixteenth Triplet"
            }
        }
        
        currentBeat = -1
        
        // Reset grid pattern for new beat count
        let maxBeats = max(16, beatsPerMeasure)
        for i in 0..<gridPattern.count {
            while gridPattern[i].count < maxBeats {
                gridPattern[i].append(false)
            }
        }
        
        // Reset accent pattern for new beat count
        while accentPattern.count < maxBeats {
            accentPattern.append(false)
        }
        
        setupDefaultPattern()
        
        if isPlaying {
            restartTicker()
        }
    }
    
    func updateBeatsPerMeasure(_ beats: Int) {
        beatsPerMeasure = beats
        currentBeat = -1
        
        // Ensure grid pattern accommodates new beat count
        if gridPattern.count > 0 && gridPattern[0].count < beats {
            for i in 0..<gridPattern.count {
                while gridPattern[i].count < beats {
                    gridPattern[i].append(false)
                }
            }
        }
        setupDefaultPattern()
        refreshAudioPattern()
    }
    
    func toggleGridCell(row: Int, col: Int) {
        gridPattern[row][col].toggle()
        // Set to custom beat when user modifies pattern
        if currentBeatName != "Random Beat" {
            currentBeatName = "Custom Beat"
        }
        refreshAudioPattern()
    }
    
    func toggleAccentCell(col: Int) {
        accentPattern[col].toggle()
        // Set to custom beat when user modifies accent pattern
        if currentBeatName != "Random Beat" {
            currentBeatName = "Custom Beat"
        }
        refreshAudioPattern()
    }
    
    func updateGridSize(_ size: Int) {
        gridSize = size
        gridPattern = Array(repeating: Array(repeating: false, count: max(16, beatsPerMeasure)), count: size)
        setupDefaultPattern()
        refreshAudioPattern()
    }
    
    func tapTempo() async {
        let now = currentDate()
        
        // Increment tap count (never resets, just keeps counting)
        tapCount += 1
        
        // Add to tap times for BPM calculation
        tapTimes.append(now)
        
        triggerVisualBlink()
        
        // Only keep recent taps for BPM calculation (but don't affect count)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3.0 }
        
        // Keep only the most recent taps for calculation
        if tapTimes.count > maxTapCount {
            tapTimes.removeFirst(tapTimes.count - maxTapCount)
        }
        
        // Calculate BPM if we have at least 2 taps
        if tapTimes.count >= 2 {
            let intervals = zip(tapTimes.dropFirst(), tapTimes).map { $0.timeIntervalSince($1) }
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let newBPM = 60.0 / averageInterval
            
            // Clamp BPM to reasonable range
            bpm = min(max(newBPM, tempoRange.lowerBound), tempoRange.upperBound)
            
            if isPlaying {
                updateBPM(bpm)
            }
        }
        
        // Reset the visible count three seconds after the most recent tap.
        tapResetScheduler.cancel()
        tapResetScheduler.schedule(after: .seconds(3)) { [weak self] in
            self?.tapCount = 0
        }
        await playSound(accented: false)
    }
    
    func updateGridBeats(_ beats: Int) {
        let maxBeats = max(16, beats)
        
        beatsPerMeasure = min(beats, gridBeatCountRange.upperBound)
        
        currentBeat = -1
        
        // Ensure grid pattern accommodates new beat count
        for i in 0..<gridPattern.count {
            while gridPattern[i].count < maxBeats {
                gridPattern[i].append(false)
            }
        }
        
        // Reset accent pattern for new beat count
        while accentPattern.count < maxBeats {
            accentPattern.append(false)
        }
        
        setupDefaultPattern()
    }
    
    var defaultPresets: [BeatPreset] {
        let presets: [(NoteValue, String)] = [
            (.quarter, "Quarter"),
            (.eighth, "Eighth"),
            (.sixteenth, "Sixteenth"),
            (.quarterTriplet, "Quarter Triplet"),
            (.eighthTriplet, "Eighth Triplet"),
            (.sixteenthTriplet, "Sixteenth Triplet")
        ]

        return presets.map(makeDefaultPreset)
    }

    func applyQuickPreset(_ preset: QuickPreset) {
        updateBPM(Double(preset.bpm))
        updateNoteValue(preset.noteValue)
    }

    private func makeDefaultPreset(noteValue: NoteValue, name: String) -> BeatPreset {
        let beatsPerMeasure = noteValue.beatsPerMeasure
        var gridPattern = Array(repeating: false, count: 16)
        var accentPattern = Array(repeating: false, count: 16)

        for index in 0..<beatsPerMeasure {
            gridPattern[index] = true
        }

        let accentPositions: [Int]
        switch noteValue {
        case .quarter:
            accentPositions = Array(0..<min(4, beatsPerMeasure))
        case .eighth:
            accentPositions = [0, 2, 4, 6]
        case .sixteenth:
            accentPositions = [0, 4, 8, 12]
        case .quarterTriplet:
            accentPositions = Array(0..<min(3, beatsPerMeasure))
        case .eighthTriplet:
            accentPositions = [0, 3]
        case .sixteenthTriplet:
            accentPositions = [0, 3, 6, 9]
        }

        for position in accentPositions where position < beatsPerMeasure {
            accentPattern[position] = true
        }

        let displayMode: GridDisplayMode = switch noteValue {
        case .sixteenth, .sixteenthTriplet: .subdivisionCounting
        default: .andCounting
        }

        return BeatPreset(
            name: name,
            noteValue: noteValue,
            bpm: 80,
            beatsPerMeasure: beatsPerMeasure,
            gridPattern: gridPattern,
            accentPattern: accentPattern,
            gridDisplayMode: displayMode
        )
    }

    func saveBeatPreset(name: String) async {
        guard !name.isEmpty else { return }
        // Capture the requested beat before loading can suspend and the user edits it.
        let preset = BeatPreset(
            name: name,
            noteValue: noteValue,
            bpm: bpm,
            beatsPerMeasure: beatsPerMeasure,
            gridPattern: gridPattern[0],
            accentPattern: accentPattern,
            gridDisplayMode: gridDisplayMode
        )
        await loadSavedPresets()
        guard hasLoadedPresets else { return }
        
        // Remove existing preset with same name
        savedBeats.removeAll { $0.name == name }
        savedBeats.append(preset)
        currentBeatName = name
        await persistPresets()
    }

    // MARK: - Preset persistence

    /// Persists the current presets through the storage supplied by AppBrain.
    /// Nothing leaves the device in the live implementation - see PRIVACY.md.
    private func persistPresets() async {
        let previousSave = presetSaveTask
        let presets = savedBeats
        presetSaveRevision += 1
        let revision = presetSaveRevision
        isSavingPresets = true

        // A committed edit outlives its screen. Await the previous write rather
        // than relying on actor scheduling to preserve submission order.
        let task = Task {
            await previousSave?.value
            do {
                try await presetRepository.savePresets(presets)
                if revision == presetSaveRevision { presetSaveError = nil }
            } catch {
                if revision == presetSaveRevision {
                    presetSaveError = error.localizedDescription
                }
            }
        }
        presetSaveTask = task
        await task.value
        if revision == presetSaveRevision {
            presetSaveTask = nil
            isSavingPresets = false
        }
    }

    /// Retries the current unsaved collection without adding or deleting anything again.
    func retrySavingPresets() async {
        guard hasLoadedPresets, presetSaveError != nil else { return }
        await persistPresets()
    }

    /// Loads once after success. Failed requests can be retried without rebuilding the feature.
    func loadSavedPresets() async {
        guard !hasLoadedPresets else { return }
        if let presetLoadTask {
            await presetLoadTask.value
            return
        }
        isLoadingPresets = true
        // Startup and a newly opened screen share one load. Cancelling one
        // caller must not cancel the work another caller still needs.
        let task = Task {
            defer {
                isLoadingPresets = false
                presetLoadTask = nil
            }
            do {
                savedBeats = try await presetRepository.loadPresets()
                hasLoadedPresets = true
                presetLoadError = nil
            } catch {
                presetLoadError = error.localizedDescription
            }
        }
        presetLoadTask = task
        await task.value
    }
    
    func loadBeatPreset(_ preset: BeatPreset) {
        var gridPattern = self.gridPattern
        var accentPattern = self.accentPattern
        noteValue = preset.noteValue
        bpm = preset.bpm
        beatsPerMeasure = preset.beatsPerMeasure
        gridDisplayMode = preset.gridDisplayMode
        currentBeatName = preset.name
        
        // Update grid patterns
        for i in 0..<gridPattern.count {
            for j in 0..<gridPattern[i].count {
                if j < preset.gridPattern.count {
                    gridPattern[i][j] = preset.gridPattern[j]
                } else {
                    gridPattern[i][j] = false
                }
            }
        }
        
        // Update accent pattern
        for i in 0..<accentPattern.count {
            if i < preset.accentPattern.count {
                accentPattern[i] = preset.accentPattern[i]
            } else {
                accentPattern[i] = false
            }
        }
        self.gridPattern = gridPattern
        self.accentPattern = accentPattern
        
        if isPlaying {
            restartTicker()
        }
    }
    
    func deleteBeatPreset(_ preset: BeatPreset) async {
        await loadSavedPresets()
        guard hasLoadedPresets else { return }
        savedBeats.removeAll { $0.id == preset.id }
        if currentBeatName == preset.name {
            currentBeatName = "Eighth"
        }
        await persistPresets()
    }
    
    func randomizeBeat() {
        var gridPattern = self.gridPattern
        var accentPattern = self.accentPattern
        // Randomize note value
        let allNoteValues = NoteValue.allCases
        let randomNoteValue = allNoteValues.randomElement()!
        
        // Randomize display mode
        let randomDisplayMode = GridDisplayMode.allCases.randomElement()!
        
        // Apply randomized settings (keep BPM unchanged)
        noteValue = randomNoteValue
        beatsPerMeasure = randomNoteValue.beatsPerMeasure
        gridDisplayMode = randomDisplayMode
        
        // Clear current pattern
        for i in 0..<gridPattern.count {
            for j in 0..<gridPattern[i].count {
                gridPattern[i][j] = false
            }
        }
        
        // Clear accent pattern
        for i in 0..<accentPattern.count {
            accentPattern[i] = false
        }
        
        // Generate random beat pattern
        let maxActiveBeats = min(beatsPerMeasure, 12) // Cap at 12 for complex patterns
        let minActiveBeats = max(2, beatsPerMeasure / 4) // At least 25% of beats
        let activeBeats = Int.random(in: minActiveBeats...maxActiveBeats)
        var selectedBeats: Set<Int> = []
        
        // Always include first beat
        selectedBeats.insert(0)
        gridPattern[0][0] = true
        accentPattern[0] = true // First beat always has accent
        
        // Add random beats
        while selectedBeats.count < activeBeats {
            let randomBeat = Int.random(in: 1..<beatsPerMeasure)
            if selectedBeats.insert(randomBeat).inserted {
                gridPattern[0][randomBeat] = true
                
                // Random chance for accent (25% for non-first beats)
                if Int.random(in: 1...4) == 1 {
                    accentPattern[randomBeat] = true
                }
            }
        }
        
        self.gridPattern = gridPattern
        self.accentPattern = accentPattern

        // Update timer if playing
        if isPlaying {
            restartTicker()
        }
        
        currentBeatName = "Random Beat"
    }
    
    func resetToBasicBeat() {
        noteValue = .eighth
        bpm = 80
        beatsPerMeasure = 8
        gridDisplayMode = .andCounting
        
        // Reset current beat properly
        if isPlaying {
            currentBeat = -1 // Will become 0 on next tick
        } else {
            currentBeat = -1 // Stopped state
        }
        
        // Set up basic 4/4 pattern
        setupDefaultPattern()
        
        // Update timer if playing
        if isPlaying {
            restartTicker()
        }
        
        currentBeatName = "Eighth"
    }

    private func restartTicker() {
        refreshAudioPattern()
        startTicker(after: tickInterval)
    }

    private func playbackPattern(restart: Bool) -> MetronomePlaybackPattern {
        MetronomePlaybackPattern(
            interval: (60.0 / bpm) / noteValue.multiplier,
            beats: (0..<beatsPerMeasure).map { beat in
                guard beat < gridPattern[0].count, gridPattern[0][beat] else { return nil }
                return beat < accentPattern.count && accentPattern[beat]
            },
            restartFromFirstBeat: restart
        )
    }

    private func refreshAudioPattern() {
        guard isPlaying else { return }
        playbackUpdateTask?.cancel()
        patternRevision += 1
        let requestedPatternRevision = patternRevision
        lastPlaybackStep = nil
        let pattern = playbackPattern(restart: currentBeat < 0)
        let revision = playbackRevision
        playbackUpdateTask = Task {
            defer {
                if requestedPatternRevision == patternRevision { playbackUpdateTask = nil }
            }
            guard !Task.isCancelled else { return }
            let operation = enqueueAudioOperation {
                guard revision == self.playbackRevision,
                      requestedPatternRevision == self.patternRevision else { return }
                try await self.audioPlayer.schedulePlayback(pattern, initialDelay: pattern.interval)
            }
            do {
                try await operation.value
            } catch {
                guard revision == playbackRevision,
                      requestedPatternRevision == patternRevision else { return }
                audioError = error.localizedDescription
                await stop()
            }
        }
    }

    private func startTicker(after initialDelay: Duration) {
        tickerRevision += 1
        let revision = tickerRevision
        ticker.start(
            after: initialDelay,
            repeatingEvery: .seconds(1.0 / 60.0)
        ) { [weak self] in
            await self?.tick(revision: revision)
        }
    }

    private var tickInterval: Duration {
        .seconds((60.0 / bpm) / noteValue.multiplier)
    }
}
