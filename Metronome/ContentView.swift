//
//  ContentView.swift
//  Metronome
//
//  Created by Alexander Friedl on 21.06.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    private var metronome: MetronomeManager { viewModel.metronome }
    
    var body: some View {
        ZStack {
            // Background with animated stars
            Color(hex: "#1C1C1B")
                .ignoresSafeArea()
            
            StarFieldView(metronome: metronome)
                .ignoresSafeArea()
                .allowsHitTesting(false) // Don't block UI interactions
            
            // Main content
            GeometryReader { geometry in
                content
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $viewModel.isShowingGridSettings) {
            GridSettingsView()
        }
        .sheet(isPresented: $viewModel.isShowingBeatPresets) {
            BeatPresetsView()
        }
        .sheet(isPresented: $viewModel.isShowingNoteValuePicker) {
            NoteValuePicker()
        }
    }
    
    private var content: some View {
        VStack(spacing: 12) {
                // Header with settings
                HStack {
                    Button(action: viewModel.showBeatPresets) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PRESET")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
                            
                            Text(metronome.currentBeatName.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: viewModel.showSettings) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#242424").opacity(0.8))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#303030"), lineWidth: 1)
                                )
                            
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // BPM Display
                VStack {
                    HStack(spacing: 20) {
                        Button(action: viewModel.decreaseBPM) {
                            Image(systemName: "minus")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                            // Long press action
                        } onPressingChanged: { pressing in
                            if pressing {
                                viewModel.startRepeatingBPMDecrease()
                            } else {
                                viewModel.stopRepeatingBPMChange()
                            }
                        }
                        
                        // Custom BPM Picker
                        VStack(spacing: 0) {
                            // Upper value (only show if not at minimum)
                            if Int(metronome.bpm) > 40 {
                                Text("\(Int(metronome.bpm) - 1)")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.2))
                                    .frame(height: 60)
                            } else {
                                Spacer()
                                    .frame(height: 60)
                            }
                            
                            // Current value with background
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#303030"))
                                    .frame(width: 120, height: 60)
                                
                                Text("\(Int(metronome.bpm))")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(Color(hex: "#DDDDDD"))
                            }
                            .frame(height: 60)
                            
                            // Lower value (only show if not at maximum)
                            if Int(metronome.bpm) < 200 {
                                Text("\(Int(metronome.bpm) + 1)")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.2))
                                    .frame(height: 60)
                            } else {
                                Spacer()
                                    .frame(height: 60)
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    viewModel.dragBPM(verticalTranslation: gesture.translation.height)
                                }
                        )
                        
                        Button(action: viewModel.increaseBPM) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                            // Long press action
                        } onPressingChanged: { pressing in
                            if pressing {
                                viewModel.startRepeatingBPMIncrease()
                            } else {
                                viewModel.stopRepeatingBPMChange()
                            }
                        }
                    }
                }
                
                Spacer()
                    .frame(height: 20)
                
                Button(action: viewModel.showNoteValuePicker) {
                    HStack(spacing: 8) {
                        Text("PATTERN")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
                        
                        Text(metronome.noteValue.displayName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "#F54206"))
                        
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#242424"))
                    .cornerRadius(20)
                }
                
                // Beat Pattern Grid
                GridView(metronome: metronome)
                
                Spacer()
                    .frame(maxHeight: 20)
                
                // Play and Tap Tempo Buttons
                HStack(spacing: 20) {
                    // Tap Tempo Button
                    Button(action: viewModel.recordTapTempo) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#242424"))
                                .frame(width: 64, height: 64)
                            
                            VStack(spacing: 2) {
                                Text("TAP")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                
                                // Show tap count
                                if metronome.tapCount > 0 {
                                    Text("\(metronome.tapCount)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(hex: "#F54206"))
                                        .transition(.opacity)
                                }
                            }
                        }
                    }
                    
                    // Central Play Button
                    ZStack {
                        Circle()
                            .fill(metronome.isPlaying ? Color(hex: "#F54206") : Color(hex: "#242424"))
                            .frame(width: 96, height: 96)
                            .scaleEffect(viewModel.isPlayButtonPressed ? 0.95 : (metronome.shouldBlink ? 1.1 : 1.0))
                            .animation(.easeInOut(duration: 0.1), value: metronome.shouldBlink)
                            .animation(.easeInOut(duration: 0.1), value: viewModel.isPlayButtonPressed)
                        
                        Image(systemName: metronome.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "#DDDDDD"))
                            .scaleEffect(viewModel.isPlayButtonPressed ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: viewModel.isPlayButtonPressed)
                    }
                    .onTapGesture {
                        viewModel.togglePlayback()
                    }
                    .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
                        // Never triggers
                    } onPressingChanged: { pressing in
                        viewModel.isPlayButtonPressed = pressing
                    }
                    
                    // Randomize Beat Button
                    Button(action: viewModel.randomizeBeat) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#242424"))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "shuffle")
                                .font(.system(size: 19))
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
    }
    
}

struct GridView: View {
    @ObservedObject var metronome: MetronomeManager
    
    var body: some View {
        VStack(spacing: 6) {
            // Main grid tiles
            ForEach(0..<numberOfRows(), id: \.self) { row in
                VStack(spacing: 3) {
                    HStack(spacing: 6) {
                        ForEach(0..<tilesInRow(row), id: \.self) { col in
                            let beat = row * tilesPerRow() + col
                            BeatTile(
                                beat: beat,
                                metronome: metronome,
                                isActive: beat < metronome.gridPattern[0].count && metronome.gridPattern[0][beat],
                                isCurrent: beat == metronome.currentBeat && metronome.isPlaying
                            )
                        }
                    }
                    
                    // Accent dots row
                    HStack(spacing: 6) {
                        ForEach(0..<tilesInRow(row), id: \.self) { col in
                            let beat = row * tilesPerRow() + col
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                metronome.toggleAccentCell(col: beat)
                            }) {
                                Circle()
                                    .fill(getAccentColor(for: beat))
                                    .frame(width: 10, height: 10)
                                    .frame(width: 40, height: 16) // Same width as tiles
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func numberOfRows() -> Int {
        let tilesPerRow = self.tilesPerRow()
        return (metronome.beatsPerMeasure + tilesPerRow - 1) / tilesPerRow
    }
    
    private func tilesInRow(_ row: Int) -> Int {
        let remainingBeats = metronome.beatsPerMeasure - (row * tilesPerRow())
        return min(tilesPerRow(), remainingBeats)
    }
    
    private func tilesPerRow() -> Int {
        return metronome.noteValue.isTriplet ? 3 : 4
    }
    
    
    
    private func getAccentColor(for beat: Int) -> Color {
        if beat < metronome.accentPattern.count && metronome.accentPattern[beat] {
            if beat == metronome.currentBeat && metronome.isPlaying {
                return Color(hex: "#F54206") // Orange when playing accent
            } else {
                return Color(hex: "#303030") // Gray accent dots
            }
        } else {
            return Color.clear
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Beat Configuration") {
                    Stepper(
                        "Beats per Measure: \(viewModel.beatsPerMeasure)",
                        value: Binding(
                            get: { viewModel.beatsPerMeasure },
                            set: { viewModel.beatsPerMeasure = $0 }
                        ),
                        in: 1...16
                    )
                    .foregroundColor(Color(hex: "#DDDDDD"))
                    .accentColor(Color(hex: "#F54206"))
                }
            }
            .background(Color(hex: "#1C1C1B"))
            .scrollContentBackground(.hidden)
            .foregroundColor(Color(hex: "#DDDDDD"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.finish()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                }
            }
        }
        .background(Color(hex: "#1C1C1B"))
        .preferredColorScheme(.dark)
    }
}

struct GridSettingsView: View {
    @StateObject private var viewModel = GridSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Grid Configuration") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Number of Beats: \(viewModel.beatsPerMeasure)")
                            .foregroundColor(Color(hex: "#DDDDDD"))
                        
                        let maxBeats = viewModel.maximumBeatCount
                        Slider(value: Binding(
                            get: { Double(viewModel.beatsPerMeasure) },
                            set: viewModel.updateBeatCount
                        ), in: 1...Double(maxBeats), step: 1)
                        .accentColor(Color(hex: "#F54206"))
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                            Spacer()
                            Text("\(maxBeats)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                        }
                        
                        Text("Note: Triplets are limited to 12 beats max")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(Color(hex: "#1C1C1B"))
            .scrollContentBackground(.hidden)
            .foregroundColor(Color(hex: "#DDDDDD"))
            .navigationTitle("Grid Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.finish()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                }
            }
        }
        .background(Color(hex: "#1C1C1B"))
        .preferredColorScheme(.dark)
    }
}

struct BeatPresetsView: View {
    @StateObject private var viewModel = BeatPresetsViewModel()
    @Environment(\.dismiss) private var dismiss

    private var metronome: MetronomeManager { viewModel.metronome }
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Beat") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(metronome.currentBeatName)
                                .font(.headline)
                                .foregroundColor(Color(hex: "#DDDDDD"))
                            Text("\(metronome.noteValue.displayName) • \(Int(metronome.bpm)) BPM • \(metronome.beatsPerMeasure) beats")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button("Save As...") {
                            viewModel.beginSavingCurrentBeat()
                        }
                        .foregroundColor(Color(hex: "#F54206"))
                    }
                    .listRowBackground(Color(hex: "#303030"))
                }
                
                Section("Presets") {
                    ForEach(viewModel.defaultPresets, id: \.noteValue) { preset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                Text("\(preset.noteValue.displayName) • \(Int(preset.bpm)) BPM • \(preset.beatsPerMeasure) beats")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button("Load") {
                                viewModel.load(preset)
                                dismiss()
                            }
                            .foregroundColor(Color(hex: "#F54206"))
                            .disabled(preset.name == metronome.currentBeatName)
                            .opacity(preset.name == metronome.currentBeatName ? 0.5 : 1.0)
                        }
                        .listRowBackground(Color(hex: "#303030"))
                    }
                }
                
                Section("Saved Beats") {
                    ForEach(metronome.savedBeats) { preset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                Text("\(preset.noteValue.displayName) • \(Int(preset.bpm)) BPM • \(preset.beatsPerMeasure) beats")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button("Load") {
                                viewModel.load(preset)
                                dismiss()
                            }
                            .foregroundColor(Color(hex: "#F54206"))
                            .disabled(preset.name == metronome.currentBeatName)
                            .opacity(preset.name == metronome.currentBeatName ? 0.5 : 1.0)
                        }
                        .listRowBackground(Color(hex: "#303030"))
                    }
                    .onDelete { indexSet in
                        viewModel.deleteSavedBeats(at: indexSet)
                    }
                }
            }
            .background(Color(hex: "#1C1C1B"))
            .scrollContentBackground(.hidden)
            .foregroundColor(Color(hex: "#DDDDDD"))
            .navigationTitle("Beat Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.reset()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.finish()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                }
            }
        }
        .background(Color(hex: "#1C1C1B"))
        .preferredColorScheme(.dark)
        .alert("Save Beat Preset", isPresented: $viewModel.isShowingSaveDialog) {
            TextField("Beat Name", text: $viewModel.newBeatName)
                .foregroundColor(.black)
            Button("Save") {
                viewModel.saveCurrentBeat()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for this beat configuration")
        }
    }
    
}

#Preview {
    ContentView()
}
