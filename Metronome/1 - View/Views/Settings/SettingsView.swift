import SwiftUI

struct SettingsView: View {
    @Environment(\.appColourTheme) private var theme
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
                    .foregroundColor(theme.text)
                    .accentColor(theme.accent)
                }
            }
            .background(theme.background)
            .scrollContentBackground(.hidden)
            .foregroundColor(theme.text)
            .navigationTitle("Settings")
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
