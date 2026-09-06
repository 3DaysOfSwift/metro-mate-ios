import Foundation

protocol PresetRepository {
    func loadPresets() throws -> [BeatPreset]
    func savePresets(_ presets: [BeatPreset]) throws
}

