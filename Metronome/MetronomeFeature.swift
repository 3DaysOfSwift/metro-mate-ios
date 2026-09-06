import Combine

@MainActor
protocol MetronomeFeature: AnyObject, ObservableObject
where ObjectWillChangePublisher == ObservableObjectPublisher {
    var isPlaying: Bool { get }
    var bpm: Double { get }
    var beatsPerMeasure: Int { get }
    var currentBeat: Int { get }
    var shouldBlink: Bool { get }
    var gridPattern: [[Bool]] { get }
    var accentPattern: [Bool] { get }
    var noteValue: NoteValue { get }
    var gridDisplayMode: GridDisplayMode { get }
    var currentBeatName: String { get }
    var savedBeats: [BeatPreset] { get }
    var defaultPresets: [BeatPreset] { get }
    var quickPresets: [QuickPreset] { get }
    var tapCount: Int { get }

    func togglePlayback()
    func updateBPM(_ bpm: Double)
    func adjustedBPM(by amount: Double) -> Double
    func adjustBPM(by amount: Double)
    func updateNoteValue(_ noteValue: NoteValue)
    func updateBeatsPerMeasure(_ beats: Int)
    func updateGridBeats(_ beats: Int)
    func toggleGridCell(row: Int, col: Int)
    func toggleAccentCell(col: Int)
    func tapTempo()
    func saveBeatPreset(name: String)
    func loadBeatPreset(_ preset: BeatPreset)
    func applyQuickPreset(_ preset: QuickPreset)
    func deleteBeatPreset(_ preset: BeatPreset)
    func randomizeBeat()
    func resetToBasicBeat()
}
