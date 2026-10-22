//
//  CapybaraAnimator.swift
//  CapyDoro
//
//  Steps through sprite frames on its own timer. It only knows "which frame number now";
//  the view turns that number into an image.
//

import Foundation
import Observation

@Observable
final class CapybaraAnimator {
    /// The frame to show. Views read this, so they redraw on every step.
    private(set) var frameIndex = 0

    @ObservationIgnored private let ticker: Ticking
    /// Asked each time playback starts: false when Reduce Motion is on or animations are off.
    @ObservationIgnored private let isMotionAllowed: () -> Bool
    @ObservationIgnored private var frameCount = 0

    init(ticker: Ticking, isMotionAllowed: @escaping () -> Bool) {
        self.ticker = ticker
        self.isMotionAllowed = isMotionAllowed
    }

    /// Loops `frameCount` frames. With motion off, or a single frame, it just shows frame 0.
    func play(frameCount: Int, framesPerSecond: Double) {
        stop()
        guard frameCount > 1, isMotionAllowed() else { return }
        self.frameCount = frameCount
        ticker.start(interval: 1 / framesPerSecond) { [weak self] in
            self?.advance()
        }
    }

    /// Stops the timer (saves energy) and goes back to the first frame.
    func stop() {
        ticker.stop()
        frameIndex = 0
    }

    private func advance() {
        frameIndex = (frameIndex + 1) % frameCount   // `%` wraps back to 0 after the last frame
    }
}
