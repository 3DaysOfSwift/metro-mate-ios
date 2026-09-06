//
//  ContentView.swift
//  Metronome
//
//  Created by Alexander Friedl on 21.06.25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.appColourTheme) private var theme
    @State private var viewModel = ContentViewModel()

    
    var body: some View {
        ZStack {
            // Background with animated stars
            theme.background
                .ignoresSafeArea()
            
            StarFieldView()
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
                if let error = viewModel.audioError {
                    VStack {
                        Text("Audio unavailable: \(error)")
                            .foregroundStyle(theme.errorText)
                        Button("Retry audio") {
                            Task { await viewModel.retryAudio() }
                        }
                    }
                    .padding(.horizontal)
                }
                if viewModel.isStartingPlayback {
                    ProgressView("Preparing audio…")
                        .tint(theme.text)
                }
                // Header with settings
                HStack {
                    Button(action: viewModel.showBeatPresets) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PRESET")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(theme.text.opacity(0.6))
                            
                            Text(viewModel.currentBeatName.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(theme.text)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: viewModel.showSettings) {
                        ZStack {
                            Circle()
                                .fill(theme.surface.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(theme.elevatedSurface, lineWidth: 1)
                                )
                            
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.text)
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
                                .foregroundColor(theme.text)
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
                            if Int(viewModel.bpm) > viewModel.minimumBPM {
                                Text("\(Int(viewModel.bpm) - 1)")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(theme.text.opacity(0.2))
                                    .frame(height: 60)
                            } else {
                                Spacer()
                                    .frame(height: 60)
                            }
                            
                            // Current value with background
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.elevatedSurface)
                                    .frame(width: 120, height: 60)
                                
                                Text("\(Int(viewModel.bpm))")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(theme.text)
                            }
                            .frame(height: 60)
                            
                            // Lower value (only show if not at maximum)
                            if Int(viewModel.bpm) < viewModel.maximumBPM {
                                Text("\(Int(viewModel.bpm) + 1)")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(theme.text.opacity(0.2))
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
                                .foregroundColor(theme.text)
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
                            .foregroundColor(theme.text.opacity(0.6))
                        
                        Text(viewModel.noteValue.displayName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.accent)
                        
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.text.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.surface)
                    .cornerRadius(20)
                }
                
                // Beat Pattern Grid
                GridView()
                
                Spacer()
                    .frame(maxHeight: 20)
                
                // Play and Tap Tempo Buttons
                HStack(spacing: 20) {
                    // Tap Tempo Button
                    Button {
                        Task { await viewModel.recordTapTempo() }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.surface)
                                .frame(width: 64, height: 64)
                            
                            VStack(spacing: 2) {
                                Text("TAP")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(theme.text)
                                
                                // Show tap count
                                if viewModel.tapCount > 0 {
                                    Text("\(viewModel.tapCount)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(theme.accent)
                                        .transition(.opacity)
                                }
                            }
                        }
                    }
                    
                    // Central Play Button
                    ZStack {
                        Circle()
                            .fill(viewModel.isPlaying ? theme.accent : theme.surface)
                            .frame(width: 96, height: 96)
                            .scaleEffect(viewModel.isPlayButtonPressed ? 0.95 : (viewModel.shouldBlink ? 1.1 : 1.0))
                            .animation(.easeInOut(duration: 0.1), value: viewModel.shouldBlink)
                            .animation(.easeInOut(duration: 0.1), value: viewModel.isPlayButtonPressed)
                        
                        Image(systemName: viewModel.isPlaying || viewModel.isStartingPlayback ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(theme.text)
                            .scaleEffect(viewModel.isPlayButtonPressed ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: viewModel.isPlayButtonPressed)
                    }
                    .onTapGesture {
                        Task { await viewModel.togglePlayback() }
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
                                .fill(theme.surface)
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "shuffle")
                                .font(.system(size: 19))
                                .foregroundColor(theme.text)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
    }
    
}

#Preview {
    ContentView()
}
