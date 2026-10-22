//
//  PoseAnimationController.swift
//  CapyDoro
//
//  Picks the capybara pose for the timer's state (stand, walk, sit, hot spring, sleep) and
//  animates it only while the countdown runs. Idle, paused and waiting show a still frame,
//  so the frame timer is off whenever nothing is counting down.
//
//  It watches the engine directly with `withObservationTracking` (the same mechanism SwiftUI
//  uses to redraw views) instead of relying on the menu bar view's lifecycle.
//

import Foundation
import Observation

@Observable
final class PoseAnimationController {
    /// The pose the menu bar should show right now.
    private(set) var pose: Pose = .stand
    @ObservationIgnored private var isAnimating = false

    @ObservationIgnored private let engine: PomodoroEngine
    @ObservationIgnored private let animator: CapybaraAnimator
    /// How many frames each pose has (walk = the whole walk ×3 + hop loop).
    @ObservationIgnored private let frameCounts: [Pose: Int]

    init(engine: PomodoroEngine, animator: CapybaraAnimator, frameCounts: [Pose: Int]) {
        self.engine = engine
        self.animator = animator
        self.frameCounts = frameCounts
        watchEngine()
    }

    private func watchEngine() {
        // Reads inside the first closure are "watched". When any of them is about to change,
        // `onChange` runs once, so we schedule another look right after the change lands.
        let (newPose, running) = withObservationTracking {
            (Pose.for(phase: engine.phase, isRunning: engine.isRunning, isPaused: engine.isPaused),
             engine.isRunning)
        } onChange: { [weak self] in
            Task { @MainActor in self?.watchEngine() }
        }
        update(pose: newPose, running: running)
    }

    private func update(pose newPose: Pose, running: Bool) {
        let frameCount = frameCounts[newPose] ?? 0
        let animate = running && frameCount > 1
        guard newPose != pose || animate != isAnimating else { return }   // only act on a real change

        pose = newPose
        isAnimating = animate
        if animate {
            animator.play(frameCount: frameCount, framesPerSecond: newPose.framesPerSecond)
        } else {
            animator.stop()   // back to frame 0, timer off
        }
    }
}
