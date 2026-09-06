struct QuickPreset: Identifiable {
    let title: String
    let bpm: Int
    let noteValue: NoteValue

    var id: String { title }
}
