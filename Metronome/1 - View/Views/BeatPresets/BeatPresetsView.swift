import SwiftUI

struct BeatPresetsView: View {
    @Environment(\.appColourTheme) private var theme
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
                                .foregroundColor(theme.text)
                            Text("\(viewModel.noteValue.displayName) • \(Int(viewModel.bpm)) BPM • \(viewModel.beatsPerMeasure) beats")
                                .font(.caption)
                                .foregroundColor(theme.text.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button("Save As...") {
                            viewModel.beginSavingCurrentBeat()
                        }
                        .foregroundColor(theme.accent)
                    }
                    .listRowBackground(theme.elevatedSurface)
                }
                
                Section("Presets") {
                    ForEach(viewModel.defaultPresets, id: \.noteValue) { preset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(theme.text)
                                Text("\(preset.noteValue.displayName) • \(Int(preset.bpm)) BPM • \(preset.beatsPerMeasure) beats")
                                    .font(.caption)
                                    .foregroundColor(theme.text.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button("Load") {
                                viewModel.load(preset)
                                dismiss()
                            }
                            .foregroundColor(theme.accent)
                            .disabled(preset.name == viewModel.currentBeatName)
                            .opacity(preset.name == viewModel.currentBeatName ? 0.5 : 1.0)
                        }
                        .listRowBackground(theme.elevatedSurface)
                    }
                }
                
                Section("Saved Beats") {
                    if viewModel.isLoading { ProgressView("Loading saved beats…") }
                    if viewModel.isSaving { ProgressView("Saving changes…") }
                    if let error = viewModel.saveError {
                        Text("Changes are not saved: \(error)")
                        Button("Retry saving") {
                            Task { await viewModel.retrySavingPresets() }
                        }
                    }
                    if let error = viewModel.loadError {
                        Text("Could not load saved beats: \(error)")
                        Button("Retry") {
                            Task { await viewModel.loadSavedPresets() }
                        }
                    }
                    ForEach(viewModel.savedBeats) { preset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(theme.text)
                                Text("\(preset.noteValue.displayName) • \(Int(preset.bpm)) BPM • \(preset.beatsPerMeasure) beats")
                                    .font(.caption)
                                    .foregroundColor(theme.text.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button("Load") {
                                viewModel.load(preset)
                                dismiss()
                            }
                            .foregroundColor(theme.accent)
                            .disabled(preset.name == viewModel.currentBeatName)
                            .opacity(preset.name == viewModel.currentBeatName ? 0.5 : 1.0)
                        }
                        .listRowBackground(theme.elevatedSurface)
                    }
                    .onDelete { indexSet in
                        Task { await viewModel.deleteSavedBeats(at: indexSet) }
                    }
                }
            }
            .background(theme.background)
            .scrollContentBackground(.hidden)
            .foregroundColor(theme.text)
            .navigationTitle("Beat Presets")
            .task { await viewModel.loadSavedPresets() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.reset()
                        dismiss()
                    }
                    .foregroundColor(theme.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.finish()
                        dismiss()
                    }
                    .foregroundColor(theme.text)
                }
            }
        }
        .background(theme.background)
        .preferredColorScheme(.dark)
        .alert("Save Beat Preset", isPresented: $viewModel.isShowingSaveDialog) {
            TextField("Beat Name", text: $viewModel.newBeatName)
                .foregroundColor(theme.alertInputText)
            Button("Save") {
                Task { await viewModel.saveCurrentBeat() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for this beat configuration")
        }
    }
    
}
