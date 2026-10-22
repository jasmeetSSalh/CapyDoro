//
//  FocusAnimationController.swift
//  CapyDoro
//
//  Starts the capybara walking when focus is running and stops it otherwise (idle, paused,
//  waiting, breaks), so the frame timer never runs when nothing is moving.
//
//  It watches the engine directly with `withObservationTracking` (the same mechanism SwiftUI
//  uses to redraw views) instead of relying on the menu bar view's lifecycle.
//

import Foundation
import Observation

@Observable
final class FocusAnimationController {
    /// True while focus is running. The menu bar shows sprite frames only then.
    private(set) var isWalking = false

    @ObservationIgnored private let engine: PomodoroEngine
    @ObservationIgnored private let animator: CapybaraAnimator
    @ObservationIgnored private let frameCount: Int

    init(engine: PomodoroEngine, animator: CapybaraAnimator, frameCount: Int) {
        self.engine = engine
        self.animator = animator
        self.frameCount = frameCount
        watchEngine()
    }

    private func watchEngine() {
        // Reads inside the first closure are "watched". When any of them is about to change,
        // `onChange` runs once, so we schedule another look right after the change lands.
        let shouldWalk = withObservationTracking {
            engine.phase == .focus && engine.isRunning
        } onChange: { [weak self] in
            Task { @MainActor in self?.watchEngine() }
        }
        update(walking: shouldWalk)
    }

    private func update(walking: Bool) {
        guard walking != isWalking else { return }   // only act on a real change
        isWalking = walking
        if walking {
            animator.play(frameCount: frameCount, framesPerSecond: Pose.walk.framesPerSecond)
        } else {
            animator.stop()
        }
    }
}
