import Foundation

final class UserDefaultsPresetRepository: PresetRepository {
    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        userDefaults: UserDefaults,
        storageKey: String
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    func loadPresets() throws -> [BeatPreset] {
        guard let data = userDefaults.data(forKey: storageKey) else { return [] }

        do {
            return try JSONDecoder().decode([BeatPreset].self, from: data)
        } catch {
            userDefaults.removeObject(forKey: storageKey)
            throw error
        }
    }

    func savePresets(_ presets: [BeatPreset]) throws {
        let data = try JSONEncoder().encode(presets)
        userDefaults.set(data, forKey: storageKey)
    }
}
