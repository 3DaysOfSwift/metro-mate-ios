import Foundation
import Combine

@MainActor
final class MetronomeManager: MetronomeFeature {
    @Published var isPlaying = false
    @Published var bpm: Double = 60
    @Published var beatsPerMeasure = 8
    @Published var currentBeat = -1
    @Published var shouldBlink = false
    @Published var gridPattern: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 4)
    @Published var accentPattern: [Bool] = Array(repeating: false, count: 16)
    @Published var gridSize = 4
    @Published var noteValue: NoteValue = .eighth
    @Published var gridDisplayMode: GridDisplayMode = .andCounting
    @Published var currentBeatName: String = "Eighth"
    @Published var savedBeats: [BeatPreset] = []
    @Published var tapTimes: [Date] = []
    @Published var tapCount: Int = 0
    private let maxTapCount = 8
    let beatCountRange = 1...16
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
        audioPlayer.prepare()
        setupDefaultPattern()
        restorePresets()
    }
    
    private func setupDefaultPattern() {
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
    }
    
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }
    
    private func start() {
        isPlaying = true
        currentBeat = -1  // Start at -1 so first increment makes it 0 (beat 1)
        
        audioPlayer.startIfNeeded()
        
        startTicker(after: .milliseconds(10))
    }
    
    private func stop() {
        isPlaying = false
        ticker.stop()
        blinkScheduler.cancel()
        currentBeat = -1
        shouldBlink = false
        
        audioPlayer.stop()
    }
    
    private func tick() {
        // Update beat counter BEFORE playing sound and visual update
        currentBeat = (currentBeat + 1) % beatsPerMeasure
        
        // Update visual immediately
        triggerVisualBlink()
        
        // Check if this beat should play based on grid pattern
        let shouldPlayBeat = currentBeat < gridPattern[0].count && gridPattern[0][currentBeat]
        
        if shouldPlayBeat {
            playClick()
        }
    }
    
    private func playClick() {
        let shouldAccent = currentBeat < accentPattern.count && accentPattern[currentBeat]
        audioPlayer.playClick(accented: shouldAccent)
    }
    
    private func playTapSound() {
        audioPlayer.playClick(accented: false)
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
        max(40, min(200, bpm + amount))
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
    }
    
    func toggleGridCell(row: Int, col: Int) {
        gridPattern[row][col].toggle()
        // Set to custom beat when user modifies pattern
        if currentBeatName != "Random Beat" {
            currentBeatName = "Custom Beat"
        }
    }
    
    func toggleAccentCell(col: Int) {
        accentPattern[col].toggle()
        // Set to custom beat when user modifies accent pattern
        if currentBeatName != "Random Beat" {
            currentBeatName = "Custom Beat"
        }
    }
    
    func updateGridSize(_ size: Int) {
        gridSize = size
        gridPattern = Array(repeating: Array(repeating: false, count: max(16, beatsPerMeasure)), count: size)
        setupDefaultPattern()
    }
    
    func tapTempo() {
        let now = currentDate()
        
        // Increment tap count (never resets, just keeps counting)
        tapCount += 1
        
        // Add to tap times for BPM calculation
        tapTimes.append(now)
        
        // Play tap sound
        playTapSound()
        
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
            bpm = min(max(newBPM, 40), 200)
            
            if isPlaying {
                updateBPM(bpm)
            }
        }
        
        // Reset the visible count three seconds after the most recent tap.
        tapResetScheduler.cancel()
        tapResetScheduler.schedule(after: .seconds(3)) { [weak self] in
            self?.tapCount = 0
        }
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

    func saveBeatPreset(name: String) {
        guard !name.isEmpty else { return }
        let preset = BeatPreset(
            name: name,
            noteValue: noteValue,
            bpm: bpm,
            beatsPerMeasure: beatsPerMeasure,
            gridPattern: gridPattern[0],
            accentPattern: accentPattern,
            gridDisplayMode: gridDisplayMode
        )
        
        // Remove existing preset with same name
        savedBeats.removeAll { $0.name == name }
        savedBeats.append(preset)
        currentBeatName = name
        persistPresets()
    }

    // MARK: - Preset persistence

    /// Persists the current presets through the storage supplied by AppBrain.
    /// Nothing leaves the device in the live implementation - see PRIVACY.md.
    private func persistPresets() {
        do {
            try presetRepository.savePresets(savedBeats)
        } catch {
            print("Failed to save beat presets: \(error)")
        }
    }

    private func restorePresets() {
        do {
            savedBeats = try presetRepository.loadPresets()
        } catch {
            print("Failed to load beat presets: \(error)")
        }
    }
    
    func loadBeatPreset(_ preset: BeatPreset) {
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
        
        if isPlaying {
            restartTicker()
        }
    }
    
    func deleteBeatPreset(_ preset: BeatPreset) {
        savedBeats.removeAll { $0.id == preset.id }
        if currentBeatName == preset.name {
            currentBeatName = "Eighth"
        }
        persistPresets()
    }
    
    func randomizeBeat() {
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
        
        // Clear all patterns
        for i in 0..<gridPattern.count {
            for j in 0..<gridPattern[i].count {
                gridPattern[i][j] = false
            }
        }
        
        for i in 0..<accentPattern.count {
            accentPattern[i] = false
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
        startTicker(after: tickInterval)
    }

    private func startTicker(after initialDelay: Duration) {
        ticker.start(
            after: initialDelay,
            repeatingEvery: tickInterval
        ) { [weak self] in
            self?.tick()
        }
    }

    private var tickInterval: Duration {
        .seconds((60.0 / bpm) / noteValue.multiplier)
    }
}
