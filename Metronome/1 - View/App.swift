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
    @State private var themeManager = ThemeManager()
    init() {
        // Register shortcuts
        MetronomeShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appColourTheme, themeManager.selectedTheme)
                .simultaneousGesture(
                    TapGesture(count: 2).onEnded {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            themeManager.selectNextTheme()
                        }
                    }
                )
                .task {
                    await AppBrain.shared.applicationDidFinishLaunching()
                }
        }
    }
}
