protocol MetronomeAudioPlayer: AnyObject, Sendable {
    func prepare() async throws
    func startIfNeeded() async throws
    func stop() async
    func playClick(accented: Bool) async throws
    func schedulePlayback(_ pattern: MetronomePlaybackPattern, initialDelay: Double) async throws
    func playbackBeat() async -> Int?
    func playbackProgress() async throws -> MetronomePlaybackProgress?
}

struct MetronomePlaybackProgress: Sendable {
    let step: Int
    let beatIndex: Int?
    let skippedBeats: Int64
}

extension MetronomeAudioPlayer {
    func playbackProgress() async throws -> MetronomePlaybackProgress? {
        guard let beat = await playbackBeat() else { return nil }
        return MetronomePlaybackProgress(step: beat, beatIndex: nil, skippedBeats: 0)
    }
}
