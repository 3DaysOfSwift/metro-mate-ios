protocol MetronomeAudioPlayer: AnyObject {
    func prepare()
    func startIfNeeded()
    func stop()
    func playClick(accented: Bool)
}

