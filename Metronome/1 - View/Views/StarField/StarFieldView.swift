import SwiftUI

struct StarFieldView: View {
    @StateObject private var viewModel = StarFieldViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw all dots
                for row in viewModel.dots {
                    for dot in row {
                        let rect = CGRect(
                            x: dot.x - dot.size/2,
                            y: dot.y - dot.size/2,
                            width: dot.size,
                            height: dot.size
                        )
                        
                        // Subtle monochrome colors
                        let normalizedDistance = min(dot.distanceFromCenter / (size.width * 0.7), 1.0)
                        let opacity = 0.4 - normalizedDistance * 0.3
                        
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(Color(hex: "#DDDDDD").opacity(opacity))
                        )
                    }
                }
            }
            .onAppear {
                viewModel.appear(in: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                viewModel.resize(to: newSize)
            }
        }
        .ignoresSafeArea() // Cover entire screen including safe areas
        .onChange(of: viewModel.shouldBlink) { _, newValue in
            viewModel.metronomeDidBlink(newValue)
        }
        .onDisappear {
            viewModel.disappear()
        }
    }
}
