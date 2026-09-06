import Testing
import Observation
import Synchronization
@testable import Metronome

@MainActor
struct ThemeManagerTests {
    @Test func cyclingThemesWrapsBackToTheFirstPalette() {
        let manager = ThemeManager()
        #expect(Set(manager.themes.map(\.id)).count == 7)
        for theme in manager.themes.dropFirst() {
            manager.selectNextTheme()
            #expect(manager.selectedTheme.id == theme.id)
        }
        manager.selectNextTheme()
        #expect(manager.selectedTheme.id == AppColourTheme.classic.id)
    }

    @Test func selectedPaletteParticipatesInObservation() {
        let manager = ThemeManager()
        let notifications = Mutex(0)
        withObservationTracking {
            _ = manager.selectedTheme.id
        } onChange: {
            notifications.withLock { $0 += 1 }
        }
        manager.selectTheme(id: "Unknown")
        #expect(notifications.withLock { $0 } == 0)
        manager.selectTheme(id: AppColourTheme.midnight.id)
        #expect(notifications.withLock { $0 } == 1)
        #expect(manager.selectedTheme.id == AppColourTheme.midnight.id)
    }

    @Test func defaultsToTheExistingPalette() {
        let manager = ThemeManager()
        #expect(manager.selectedTheme.id == AppColourTheme.classic.id)
        #expect(manager.themes.count == 7)
    }

    @Test func selectingAThemeUpdatesThePaletteAndUnknownNamesDoNothing() {
        let manager = ThemeManager()
        manager.selectTheme(id: AppColourTheme.midnight.id)
        #expect(manager.selectedTheme.id == AppColourTheme.midnight.id)
        manager.selectTheme(id: "Unknown")
        #expect(manager.selectedTheme.id == AppColourTheme.midnight.id)
    }
}
