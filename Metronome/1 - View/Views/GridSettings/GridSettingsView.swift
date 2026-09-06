import SwiftUI

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
                        ), in: viewModel.sliderRange, step: 1)
                        .accentColor(Color(hex: "#F54206"))
                        
                        HStack {
                            Text("\(viewModel.minimumBeatCount)")
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
