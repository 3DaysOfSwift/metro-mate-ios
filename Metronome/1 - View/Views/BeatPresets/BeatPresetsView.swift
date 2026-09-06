import SwiftUI

struct BeatPresetsView: View {
    @StateObject private var viewModel = BeatPresetsViewModel()
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        NavigationView {
            List {
                Section("Current Beat") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(viewModel.currentBeatName)
                                .font(.headline)
                                .foregroundColor(Color(hex: "#DDDDDD"))
                            Text("\(viewModel.noteValue.displayName) • \(Int(viewModel.bpm)) BPM • \(viewModel.beatsPerMeasure) beats")
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
                            .disabled(preset.name == viewModel.currentBeatName)
                            .opacity(preset.name == viewModel.currentBeatName ? 0.5 : 1.0)
                        }
                        .listRowBackground(Color(hex: "#303030"))
                    }
                }
                
                Section("Saved Beats") {
                    if let error = viewModel.saveError {
                        Text("Changes are not saved: \(error)")
                        Button("Retry saving", action: viewModel.retrySavingPresets)
                    }
                    if let error = viewModel.loadError {
                        Text("Could not load saved beats: \(error)")
                        Button("Retry", action: viewModel.loadSavedPresets)
                    }
                    ForEach(viewModel.savedBeats) { preset in
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
                            .disabled(preset.name == viewModel.currentBeatName)
                            .opacity(preset.name == viewModel.currentBeatName ? 0.5 : 1.0)
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
            .onAppear(perform: viewModel.loadSavedPresets)
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
