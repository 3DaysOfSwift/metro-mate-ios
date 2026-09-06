import SwiftUI

struct GridView: View {
    @Environment(\.appColourTheme) private var theme
    @StateObject private var viewModel = GridViewModel()
    
    var body: some View {
        VStack(spacing: 6) {
            // Main grid tiles
            ForEach(0..<viewModel.numberOfRows, id: \.self) { row in
                VStack(spacing: 3) {
                    HStack(spacing: 6) {
                        ForEach(0..<viewModel.tilesInRow(row), id: \.self) { col in
                            let beat = row * viewModel.tilesPerRow + col
                            BeatTile(beat: beat)
                        }
                    }
                    
                    // Accent dots row
                    HStack(spacing: 6) {
                        ForEach(0..<viewModel.tilesInRow(row), id: \.self) { col in
                            let beat = row * viewModel.tilesPerRow + col
                            Button(action: {
                                viewModel.toggleAccent(at: beat)
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
    
    private func getAccentColor(for beat: Int) -> Color {
        if viewModel.isAccentActive(at: beat) {
            if viewModel.isCurrentAccent(at: beat) {
                return theme.accent // Orange when playing accent
            } else {
                return theme.elevatedSurface // Gray accent dots
            }
        } else {
            return Color.clear
        }
    }
}
