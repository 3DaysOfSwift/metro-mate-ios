protocol MetronomeAudioPlayer: AnyObject, Sendable {
    func prepare() async throws
    func startIfNeeded() async throws
    func stop() async
    func playClick(accented: Bool) async throws
    func schedulePlayback(_ pattern: MetronomePlaybackPattern, initialDelay: Double) async throws
    func playbackBeat() async -> Int?
}
