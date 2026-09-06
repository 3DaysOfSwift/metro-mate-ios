import Foundation

/// CPU-only presentation work; no UI objects or feature references cross this boundary.
actor StarFieldRenderer {
    private var dots: [[Dot]] = []
    private var canvasSize: CGSize = .zero
    private let dotSpacing: CGFloat = 10
    private var bpm: Double = 60
    private var wavePhase: CGFloat = 0
    private var pulseTime: CGFloat = 1
    private var frameIntensity: CGFloat = 1

    func render(size: CGSize, bpm: Double, wavePhase: CGFloat, pulseTime: CGFloat, intensity: CGFloat) throws -> [[Dot]] {
        try Task.checkCancellation()
        if canvasSize != size || dots.isEmpty { setupDots(in: size) }
        self.bpm = bpm
        self.wavePhase = wavePhase
        self.pulseTime = pulseTime
        self.frameIntensity = intensity
        updateDots()
        try Task.checkCancellation()
        return dots
    }

    private func setupDots(in size: CGSize) {
        canvasSize = size
        let centerX = size.width / 2
        let centerY = size.height / 2
        let columns = Int(size.width / dotSpacing) + 6
        let rows = Int(size.height / dotSpacing) + 6
        let startX = -dotSpacing * 2
        let startY = -dotSpacing * 2

        dots = (0..<rows).map { row in
            (0..<columns).map { column in
                let baseX = startX + CGFloat(column) * dotSpacing
                let baseY = startY + CGFloat(row) * dotSpacing
                let distance = hypot(baseX - centerX, baseY - centerY)
                return Dot(
                    baseX: baseX,
                    baseY: baseY,
                    x: baseX,
                    y: baseY,
                    size: 1.5,
                    distanceFromCenter: distance
                )
            }
        }
    }

    private func updateDots() {
        guard !dots.isEmpty else { return }
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let intensity = frameIntensity
        var nextDots = dots

        for row in nextDots.indices {
            for column in nextDots[row].indices {
                var dot = nextDots[row][column]
                let waveRadius = pulseTime * 600
                let waveDistance = abs(dot.distanceFromCenter - waveRadius)
                var displacement: CGFloat = 0
                var sizeMultiplier: CGFloat = 1

                if waveDistance < 80, pulseTime < 1, intensity > 0 {
                    let waveStrength = 1 - waveDistance / 80
                    let fadeOut = 1 - pulseTime
                    displacement = sin(waveDistance * 0.1) * 20 * waveStrength * fadeOut * intensity
                    sizeMultiplier = 1 + waveStrength * fadeOut * intensity
                }

                let angle = atan2(dot.baseY - centerY, dot.baseX - centerX)
                let bpmScale = max(0.3, 1 - (bpm - 80) / 120)
                let ambientWave = sin(wavePhase + dot.distanceFromCenter * 0.008) * 2 * bpmScale

                dot.x = dot.baseX
                    + cos(angle) * displacement
                    + cos(wavePhase * 0.5 + CGFloat(row) * 0.05) * ambientWave
                dot.y = dot.baseY
                    + sin(angle) * displacement
                    + sin(wavePhase * 0.5 + CGFloat(column) * 0.05) * ambientWave
                dot.size = 1.5 * sizeMultiplier
                nextDots[row][column] = dot
            }
        }
        dots = nextDots
    }
}
