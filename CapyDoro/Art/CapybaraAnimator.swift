//
//  CapybaraAnimator.swift
//  CapyDoro
//
//  Steps through sprite frames on its own timer, either looping (poses) or once (transitions).
//  It only knows "which frame number now"; the view turns that number into an image.
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
    /// Called after the last frame of a play-once animation.
    @ObservationIgnored private var onFinish: (() -> Void)?

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

    /// Plays `frameCount` frames once, then calls `completion`. Returns false (and plays
    /// nothing) when motion is off or there's only one frame, so the caller can skip ahead.
    /// `@discardableResult`: callers may ignore the returned Bool without a warning.
    @discardableResult
    func playOnce(frameCount: Int, framesPerSecond: Double, completion: @escaping () -> Void) -> Bool {
        stop()
        guard frameCount > 1, isMotionAllowed() else { return false }
        self.frameCount = frameCount
        onFinish = completion
        ticker.start(interval: 1 / framesPerSecond) { [weak self] in
            self?.advanceOnce()
        }
        return true
    }

    /// Stops the timer (saves energy), cancels a play-once, and goes back to the first frame.
    func stop() {
        ticker.stop()
        onFinish = nil
        frameIndex = 0
    }

    private func advance() {
        frameIndex = (frameIndex + 1) % frameCount   // `%` wraps back to 0 after the last frame
    }

    private func advanceOnce() {
        if frameIndex + 1 < frameCount {
            frameIndex += 1
            return
        }
        let finish = onFinish   // keep it: stop() clears it
        stop()
        finish?()
    }
}
