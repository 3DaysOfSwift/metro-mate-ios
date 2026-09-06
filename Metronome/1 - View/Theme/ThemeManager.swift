import Observation

/// App-owned presentation state. No storage, startup work, or model responsibilities.
@MainActor
@Observable
final class ThemeManager {
    let themes = [AppColourTheme.classic, AppColourTheme.midnight]
    private(set) var selectedTheme = AppColourTheme.classic

    func selectTheme(id: String) {
        guard let theme = themes.first(where: { $0.id == id }) else { return }
        selectedTheme = theme
    }
}
