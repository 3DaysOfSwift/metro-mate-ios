import SwiftUI

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
                        in: viewModel.beatCountRange
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
