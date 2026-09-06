import SwiftUI

/// The complete app palette. Opacity and layout remain local presentation choices.
struct AppColourTheme: Identifiable {
    let id: String
    let background: Color
    let surface: Color
    let elevatedSurface: Color
    let text: Color
    let accent: Color
    let errorText: Color
    let alertInputText: Color

    static let classic = AppColourTheme(
        id: "Classic",
        background: Color("ClassicBackground"),
        surface: Color(hex: "#242424"),
        elevatedSurface: Color(hex: "#303030"),
        text: Color(hex: "#DDDDDD"),
        accent: Color(hex: "#F54206"),
        errorText: .white,
        alertInputText: .black
    )

    /// An alternate palette for checking that screens honour the selected theme.
    /// Not exposed as a new customer-facing setting during the migration.
    static let midnight = AppColourTheme(
        id: "Midnight",
        background: Color(hex: "#141923"),
        surface: Color(hex: "#202837"),
        elevatedSurface: Color(hex: "#303E52"),
        text: Color(hex: "#E2E8F0"),
        accent: Color(hex: "#63B3ED"),
        errorText: .white,
        alertInputText: .black
    )
}

private struct AppColourThemeKey: EnvironmentKey {
    static let defaultValue = AppColourTheme.classic
}

extension EnvironmentValues {
    /// A presentation value, not an application model or feature-manager factory.
    var appColourTheme: AppColourTheme {
        get { self[AppColourThemeKey.self] }
        set { self[AppColourThemeKey.self] = newValue }
    }
}
