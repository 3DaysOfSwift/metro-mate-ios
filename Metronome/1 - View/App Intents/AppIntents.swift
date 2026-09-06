import AppIntents
import SwiftUI

// BPM Enum für Siri
enum BPMValue: Int, AppEnum {
    case bpm60 = 60
    case bpm70 = 70
    case bpm80 = 80
    case bpm90 = 90
    case bpm100 = 100
    case bpm110 = 110
    case bpm120 = 120
    case bpm130 = 130
    case bpm140 = 140
    case bpm150 = 150
    case bpm160 = 160
    case bpm180 = 180
    case bpm200 = 200
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "BPM")
    
    static let caseDisplayRepresentations: [BPMValue: DisplayRepresentation] = [
        .bpm60: "60",
        .bpm70: "70", 
        .bpm80: "80",
        .bpm90: "90",
        .bpm100: "100",
        .bpm110: "110",
        .bpm120: "120",
        .bpm130: "130",
        .bpm140: "140",
        .bpm150: "150",
        .bpm160: "160",
        .bpm180: "180",
        .bpm200: "200"
    ]
}

// Haupt-Intent: Öffne Metronom und spiele X Beats
struct PlayMetronomeIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Metronome"
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "BPM")
    var bpm: BPMValue
    
    static var parameterSummary: some ParameterSummary {
        Summary("Play metronome at \(\.$bpm) BPM")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let metronome = AppBrain.shared.metronome
        
        try metronome.startPlayback(atBPM: Double(bpm.rawValue))
        return .result(dialog: "Playing at \(bpm.rawValue) BPM")
    }
}

// Einfacher Start Intent
struct StartMetronomeIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Metronome"
    static let openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let metronome = AppBrain.shared.metronome
        try metronome.startPlayback()
        return .result()
    }
}

// App Shortcuts Provider
struct MetronomeShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartMetronomeIntent(),
            phrases: [
                "Start \(.applicationName)",
                "Starte \(.applicationName)",
                "\(.applicationName) start"
            ],
            shortTitle: "Start",
            systemImageName: "play.fill"
        )
        
        AppShortcut(
            intent: PlayMetronomeIntent(),
            phrases: [
                "Start \(.applicationName) at \(\.$bpm) BPM",
                "Start \(.applicationName) with \(\.$bpm) BPM",
                "Open \(.applicationName) with \(\.$bpm) BPM",
                "Öffne \(.applicationName) mit \(\.$bpm) BPM",
                "\(.applicationName) auf \(\.$bpm) BPM",
                "\(.applicationName) \(\.$bpm) BPM"
            ],
            shortTitle: "Start at BPM",
            systemImageName: "metronome"
        )
    }
}
