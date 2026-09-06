import Observation
import UIKit

struct Dot: Sendable {
    var baseX: CGFloat
    var baseY: CGFloat
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var distanceFromCenter: CGFloat
}

@MainActor
@Observable
final class StarFieldViewModel {
    private(set) var dots: [[Dot]] = []

    private let metronome: any MetronomeFeature
    var shouldBlink: Bool { metronome.shouldBlink }
    private let renderer = StarFieldRenderer()
    @ObservationIgnored private var canvasRevision = 0

    @ObservationIgnored private var canvasSize: CGSize = .zero
    @ObservationIgnored private var wavePhase: CGFloat = 0
    @ObservationIgnored private var pulseTime: CGFloat = 1
    @ObservationIgnored private var animationTask: Task<Void, Never>?

    init(brain: AppBrain? = nil) {
        let brain = brain ?? .shared
        metronome = brain.metronome
    }

    deinit {
        animationTask?.cancel()
    }

    func appear(in size: CGSize) {
        setupDots(in: size)
        startAnimation()
    }

    func resize(to size: CGSize) {
        setupDots(in: size)
    }

    func disappear() {
        animationTask?.cancel()
        animationTask = nil
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
        canvasRevision += 1
    }

    private func frameInput() -> (size: CGSize, bpm: Double, phase: CGFloat, pulse: CGFloat, intensity: CGFloat, revision: Int) {
        wavePhase += 0.03 * max(0.5, 1 - (metronome.bpm - 80) / 160)
        if pulseTime < 1 { pulseTime += 1 / 30 }
        return (canvasSize, metronome.bpm, wavePhase, pulseTime, pulseIntensity, canvasRevision)
    }

    private func startAnimation() {
        guard animationTask == nil else { return }
        animationTask = Task { [weak self, renderer] in
            let clock = ContinuousClock()
            let frameInterval = Duration.seconds(1.0 / 60.0)
            var nextFrame = clock.now.advanced(by: frameInterval)

            do {
                while !Task.isCancelled {
                    try await clock.sleep(until: nextFrame, tolerance: .zero)
                    try Task.checkCancellation()
                    guard let input = self?.frameInput() else { return }
                    let frame = try await renderer.render(
                        size: input.size, bpm: input.bpm, wavePhase: input.phase,
                        pulseTime: input.pulse, intensity: input.intensity
                    )
                    try Task.checkCancellation()
                    if self?.canvasRevision == input.revision { self?.dots = frame }

                    nextFrame = nextFrame.advanced(by: frameInterval)
                    // Skip missed frames instead of replaying them in a burst.
                    if nextFrame <= clock.now {
                        nextFrame = clock.now.advanced(by: frameInterval)
                    }
                }
            } catch is CancellationError {
                // Disappearance or ViewModel destruction ends animation.
            } catch {
                return
            }
        }
    }
}
