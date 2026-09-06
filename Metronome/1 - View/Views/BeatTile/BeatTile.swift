import SwiftUI

struct BeatTile: View {
    @Environment(\.appColourTheme) private var theme
    @StateObject private var viewModel: BeatTileViewModel

    init(beat: Int) {
        _viewModel = StateObject(wrappedValue: BeatTileViewModel(beat: beat))
    }
    
    var body: some View {
        Button(action: viewModel.toggleBeat) {
            ZStack {
                Rectangle()
                    .fill(tileColor)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    .scaleEffect(viewModel.isPressed ? 0.9 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: viewModel.isPressed)
                
                if viewModel.isActive {
                    Text(viewModel.label)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.text)
                } else {
                    Image(systemName: "minus")
                        .font(.caption)
                        .foregroundColor(theme.text)
                        .opacity(0.3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeOut(duration: 0.1)) {
                    viewModel.isPressed = pressing
                }
            },
            perform: { }
        )
    }
    
    private var tileColor: Color {
        if viewModel.isCurrent {
            return theme.accent
        } else if viewModel.isActive {
            return theme.elevatedSurface
        } else {
            return theme.surface.opacity(0.5)
        }
    }
}
