import SwiftUI

struct NoteValuePicker: View {
    @Environment(\.appColourTheme) private var theme
    @State private var viewModel = NoteValuePickerViewModel()
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header
            VStack {
                Text("BEAT PATTERN")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.text)
                    .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
            .background(theme.background)
            
            // Scrollable content
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(NoteValue.allCases, id: \.self) { noteValue in
                        noteValueButton(for: noteValue)
                    }
                }
                .padding()
                
                // Presets Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("QUICK PRESETS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.quickPresets) { preset in
                                presetButton(for: preset)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(theme.background)
        }
        .background(theme.background)
        .presentationDetents([.fraction(0.6)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    private func noteValueButton(for noteValue: NoteValue) -> some View {
        let isSelected = viewModel.noteValue == noteValue
        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.select(noteValue)
            }
        } label: {
            VStack(spacing: 8) {
                Text(noteValue.displayName)
                    .font(.system(size: 36))
                    .foregroundColor(isSelected ? theme.accent : theme.text)
                
                Text(noteValue.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.text.opacity(0.6))
                
                // Visual representation
                HStack(spacing: 2) {
                    ForEach(0..<viewModel.visualBeatCount(for: noteValue), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? theme.accent : theme.elevatedSurface)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? theme.elevatedSurface : theme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func presetButton(for preset: QuickPreset) -> some View {
        Button { viewModel.select(preset) } label: {
            VStack(spacing: 6) {
                Text(preset.title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.text)
                
                Text("\(preset.bpm)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.accent)
                
                Text(preset.noteValue.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(theme.text.opacity(0.6))
            }
            .frame(width: 80, height: 80)
            .background(theme.surface)
            .cornerRadius(12)
        }
    }

}
