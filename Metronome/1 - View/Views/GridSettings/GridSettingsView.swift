import SwiftUI

struct GridSettingsView: View {
    @Environment(\.appColourTheme) private var theme
    @StateObject private var viewModel = GridSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Grid Configuration") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Number of Beats: \(viewModel.beatsPerMeasure)")
                            .foregroundColor(theme.text)
                        
                        let maxBeats = viewModel.maximumBeatCount
                        Slider(value: Binding(
                            get: { Double(viewModel.beatsPerMeasure) },
                            set: { viewModel.updateBeatCount($0) }
                        ), in: viewModel.sliderRange, step: 1)
                        .accentColor(theme.accent)
                        
                        HStack {
                            Text("\(viewModel.minimumBeatCount)")
                                .font(.caption)
                                .foregroundColor(theme.text.opacity(0.7))
                            Spacer()
                            Text("\(maxBeats)")
                                .font(.caption)
                                .foregroundColor(theme.text.opacity(0.7))
                        }
                        
                        Text("Note: Triplets are limited to 12 beats max")
                            .font(.caption)
                            .foregroundColor(theme.text.opacity(0.7))
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(theme.background)
            .scrollContentBackground(.hidden)
            .foregroundColor(theme.text)
            .navigationTitle("Grid Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
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
    }
}
