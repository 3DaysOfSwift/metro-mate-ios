//
//  MetronomeApp.swift
//  Metronome
//
//  Created by Alexander Friedl on 21.06.25.
//

import SwiftUI
import AppIntents

@main
struct MetronomeApp: App {
    @StateObject private var themeManager = ThemeManager()
    init() {
        // Register shortcuts
        MetronomeShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appColourTheme, themeManager.selectedTheme)
                .onAppear {
                    AppBrain.shared.applicationDidFinishLaunching()
                }
        }
    }
}
