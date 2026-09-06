import Combine

/// App-owned presentation state. No storage, startup work, or model responsibilities.
@MainActor
final class ThemeManager: ObservableObject {
    let themes = [AppColourTheme.classic, AppColourTheme.midnight]
    @Published private(set) var selectedTheme = AppColourTheme.classic

    func selectTheme(id: String) {
        guard let theme = themes.first(where: { $0.id == id }) else { return }
        selectedTheme = theme
    }
}
