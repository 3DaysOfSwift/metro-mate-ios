import Observation

@MainActor
protocol MetronomeFeature: AnyObject, Observable, Sendable {
    var isPlaying: Bool { get }
    var bpm: Double { get }
    var tempoRange: ClosedRange<Double> { get }
    var beatsPerMeasure: Int { get }
    var beatCountRange: ClosedRange<Int> { get }
    var gridBeatCountRange: ClosedRange<Int> { get }
    var currentBeat: Int { get }
    var shouldBlink: Bool { get }
    var gridPattern: [Bool] { get }
    var accentPattern: [Bool] { get }
    var noteValue: NoteValue { get }
    var gridDisplayMode: GridDisplayMode { get }
    var currentBeatName: String { get }
    var savedBeats: [BeatPreset] { get }
    var presetLoadError: String? { get }
    var presetSaveError: String? { get }
    var audioError: String? { get }
    var defaultPresets: [BeatPreset] { get }
    var quickPresets: [QuickPreset] { get }
    var tapCount: Int { get }

    var isStartingPlayback: Bool { get }
    func prepareAudio() async
    var isLoadingPresets: Bool { get }
    var isSavingPresets: Bool { get }
    func retrySavingPresets() async
    func loadSavedPresets() async
    func togglePlayback() async
    func startPlayback() async throws
    func startPlayback(atBPM bpm: Double) async throws
    func updateBPM(_ bpm: Double)
    func adjustedBPM(by amount: Double) -> Double
    func adjustBPM(by amount: Double)
    func updateNoteValue(_ noteValue: NoteValue)
    func updateBeatsPerMeasure(_ beats: Int)
    func updateGridBeats(_ beats: Int)
    func toggleBeat(at beat: Int)
    func toggleAccentCell(col: Int)
    func isBeatActive(_ beat: Int) -> Bool
    func isBeatAccented(_ beat: Int) -> Bool
    func tapTempo() async
    func saveBeatPreset(name: String) async
    func loadBeatPreset(_ preset: BeatPreset)
    func applyQuickPreset(_ preset: QuickPreset)
    func deleteBeatPreset(_ preset: BeatPreset) async
    func randomizeBeat()
    func resetToBasicBeat()
}
