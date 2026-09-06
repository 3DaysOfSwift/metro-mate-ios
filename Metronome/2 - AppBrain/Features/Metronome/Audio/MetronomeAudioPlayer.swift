protocol MetronomeAudioPlayer: AnyObject {
    func prepare() throws
    func startIfNeeded() throws
    func stop()
    func playClick(accented: Bool) throws
}
