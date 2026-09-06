import Foundation
import Dispatch

actor UserDefaultsPresetRepository: PresetRepository {
    // UserDefaults has synchronous APIs. Keep its work off both the Main Actor
    // and the cooperative executor, without exposing queues to callers.
    private let executor = DispatchSerialQueue(label: "Metronome.preset-storage")
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }
    private let suiteName: String?
    private var userDefaults: UserDefaults?
    private let storageKey: String

    init(
        suiteName: String?,
        storageKey: String
    ) {
        self.suiteName = suiteName
        self.storageKey = storageKey
    }

    func loadPresets() throws -> [BeatPreset] {
        let userDefaults = try openStorage()
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
        let userDefaults = try openStorage()
        userDefaults.set(data, forKey: storageKey)
    }

    private func openStorage() throws -> UserDefaults {
        if let userDefaults { return userDefaults }
        let storage: UserDefaults
        if let suiteName {
            guard let suite = UserDefaults(suiteName: suiteName) else {
                throw CocoaError(.fileReadUnknown)
            }
            storage = suite
        } else {
            storage = .standard
        }
        userDefaults = storage
        return storage
    }
}
