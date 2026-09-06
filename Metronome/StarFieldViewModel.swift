import Combine
import UIKit

struct Dot {
    var baseX: CGFloat
    var baseY: CGFloat
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var distanceFromCenter: CGFloat
}

@MainActor
final class StarFieldViewModel: ObservableObject {
    @Published private(set) var dots: [[Dot]] = []

    let metronome: MetronomeManager
    let dotSpacing: CGFloat = 10

    private var canvasSize: CGSize = .zero
    private var wavePhase: CGFloat = 0
    private var pulseTime: CGFloat = 1
    private var animationTimer: Timer?
    private var metronomeUpdates: AnyCancellable?

    init(brain: AppBrain = .shared) {
        metronome = brain.metronome
        metronomeUpdates = metronome.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        animationTimer?.invalidate()
    }

    func appear(in size: CGSize) {
        setupDots(in: size)
        startAnimation()
    }

    func resize(to size: CGSize) {
        setupDots(in: size)
    }

    func disappear() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func metronomeDidBlink(_ didBlink: Bool) {
        guard didBlink, pulseIntensity > 0 else { return }
        pulseTime = 0
    }

    private var pulseIntensity: CGFloat {
        guard metronome.isPlaying else { return 1 }

        let isAccented = metronome.currentBeat >= 0
            && metronome.currentBeat < metronome.accentPattern.count
            && metronome.accentPattern[metronome.currentBeat]
        let baseIntensity: CGFloat = isAccented ? 1 : 0.5

        let bpmFactor: CGFloat
        if metronome.bpm <= 100 {
            bpmFactor = 1
        } else if metronome.bpm >= 180 {
            bpmFactor = 0.3
        } else {
            bpmFactor = 1 - ((metronome.bpm - 100) / 80) * 0.7
        }

        return baseIntensity * bpmFactor
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

    private func startAnimation() {
        guard animationTimer == nil else { return }
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateDots()
            }
        }
    }

    private func updateDots() {
        let speedScale = max(0.5, 1 - (metronome.bpm - 80) / 160)
        wavePhase += 0.03 * speedScale

        if pulseTime < 1 {
            pulseTime += 1 / 30
        }

        guard !dots.isEmpty else { return }
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let intensity = pulseIntensity

        for row in dots.indices {
            for column in dots[row].indices {
                var dot = dots[row][column]
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
                let bpmScale = max(0.3, 1 - (metronome.bpm - 80) / 120)
                let ambientWave = sin(wavePhase + dot.distanceFromCenter * 0.008) * 2 * bpmScale

                dot.x = dot.baseX
                    + cos(angle) * displacement
                    + cos(wavePhase * 0.5 + CGFloat(row) * 0.05) * ambientWave
                dot.y = dot.baseY
                    + sin(angle) * displacement
                    + sin(wavePhase * 0.5 + CGFloat(column) * 0.05) * ambientWave
                dot.size = 1.5 * sizeMultiplier
                dots[row][column] = dot
            }
        }
    }
}
