import Foundation

struct BeatPreset: Identifiable, Codable, Sendable {
    var id = UUID()
    let name: String
    let noteValue: NoteValue
    let bpm: Double
    let beatsPerMeasure: Int
    let gridPattern: [Bool]
    let accentPattern: [Bool]
    let gridDisplayMode: GridDisplayMode
}
