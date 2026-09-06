import Testing
@testable import Metronome

@MainActor
struct ThemeManagerTests {
    @Test func defaultsToTheExistingPalette() {
        let manager = ThemeManager()
        #expect(manager.selectedTheme.id == AppColourTheme.classic.id)
        #expect(manager.themes.count == 2)
    }

    @Test func selectingAThemeUpdatesThePaletteAndUnknownNamesDoNothing() {
        let manager = ThemeManager()
        manager.selectTheme(id: AppColourTheme.midnight.id)
        #expect(manager.selectedTheme.id == AppColourTheme.midnight.id)
        manager.selectTheme(id: "Unknown")
        #expect(manager.selectedTheme.id == AppColourTheme.midnight.id)
    }
}
