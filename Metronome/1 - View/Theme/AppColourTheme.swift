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

    /// An alternate palette available through the main view's double-tap gesture.
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

extension AppColourTheme {
    static let forest = AppColourTheme(
        id: "Forest",
        background: Color(hex: "#101E19"),
        surface: Color(hex: "#192D24"),
        elevatedSurface: Color(hex: "#294238"),
        text: Color(hex: "#E3F3E9"),
        accent: Color(hex: "#6EE7A8"),
        errorText: .white,
        alertInputText: .black
    )

    static let amethyst = AppColourTheme(
        id: "Amethyst",
        background: Color(hex: "#1D1529"),
        surface: Color(hex: "#2B203B"),
        elevatedSurface: Color(hex: "#423052"),
        text: Color(hex: "#F0E7FA"),
        accent: Color(hex: "#C4A0FF"),
        errorText: .white,
        alertInputText: .black
    )

    static let ember = AppColourTheme(
        id: "Ember",
        background: Color(hex: "#241815"),
        surface: Color(hex: "#35241F"),
        elevatedSurface: Color(hex: "#50362A"),
        text: Color(hex: "#F8EADC"),
        accent: Color(hex: "#FFBE70"),
        errorText: .white,
        alertInputText: .black
    )

    static let lagoon = AppColourTheme(
        id: "Lagoon",
        background: Color(hex: "#102027"),
        surface: Color(hex: "#19333B"),
        elevatedSurface: Color(hex: "#284B53"),
        text: Color(hex: "#E2F5F5"),
        accent: Color(hex: "#58DFDA"),
        errorText: .white,
        alertInputText: .black
    )

    static let rose = AppColourTheme(
        id: "Rose",
        background: Color(hex: "#27171F"),
        surface: Color(hex: "#3A2530"),
        elevatedSurface: Color(hex: "#563747"),
        text: Color(hex: "#FBE8F0"),
        accent: Color(hex: "#FF9DBC"),
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
