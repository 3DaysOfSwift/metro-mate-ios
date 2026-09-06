import Observation

/// App-owned presentation state. No storage, startup work, or model responsibilities.
@MainActor
@Observable
final class ThemeManager {
    let themes = [AppColourTheme.classic, AppColourTheme.midnight]
    private(set) var selectedTheme = AppColourTheme.classic

    func selectNextTheme() {
        guard let index = themes.firstIndex(where: { $0.id == selectedTheme.id }) else { return }
        selectedTheme = themes[(index + 1) % themes.count]
    }

    func selectTheme(id: String) {
        guard let theme = themes.first(where: { $0.id == id }) else { return }
        selectedTheme = theme
    }
}
