import Foundation

protocol PresetRepository: Sendable {
    func loadPresets() async throws -> [BeatPreset]
    func savePresets(_ presets: [BeatPreset]) async throws
}
