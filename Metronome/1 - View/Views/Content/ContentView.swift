//
//  ContentView.swift
//  Metronome
//
//  Created by Alexander Friedl on 21.06.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    private var metronome: any MetronomeFeature { viewModel.metronome }
    
    var body: some View {
        ZStack {
            // Background with animated stars
            Color(hex: "#1C1C1B")
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
                            .foregroundStyle(.white)
                        Button("Retry audio", action: viewModel.retryAudio)
                    }
                    .padding(.horizontal)
                }
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
                GridView()
                
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

#Preview {
    ContentView()
}
