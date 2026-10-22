//
//  PoseAnimationController.swift
//  CapyDoro
//
//  Picks the capybara pose for the timer's state (stand, walk, nap, hot spring, sleep) and
//  animates it only while the countdown runs. Idle, paused and waiting show a still frame,
//  so the frame timer is off whenever nothing is counting down.
//
//  When the phase changes it first plays a short transition (flop, dive, wake, emerge) once,
//  then the new pose takes over. Pause, resume, reset and app launch switch instantly.
//
//  It watches the engine directly with `withObservationTracking` (the same mechanism SwiftUI
//  uses to redraw views) instead of relying on the menu bar view's lifecycle.
//

import Foundation
import Observation

@Observable
final class PoseAnimationController {
    /// The pose the menu bar should show (once any transition has finished).
    private(set) var pose: Pose = .stand
    /// The transition playing right now, if any. The menu bar shows its frames instead.
    private(set) var transition: Transition?

    @ObservationIgnored private var isAnimating = false
    @ObservationIgnored private var isRunning = false
    @ObservationIgnored private var hasStarted = false

    @ObservationIgnored private let engine: PomodoroEngine
    @ObservationIgnored private let animator: CapybaraAnimator
    /// How many frames each pose has (walk = the whole walk ×3 + hop loop).
    @ObservationIgnored private let frameCounts: [Pose: Int]
    @ObservationIgnored private let transitionFrameCounts: [Transition: Int]

    init(engine: PomodoroEngine,
         animator: CapybaraAnimator,
         frameCounts: [Pose: Int],
         transitionFrameCounts: [Transition: Int] = [:]) {
        self.engine = engine
        self.animator = animator
        self.frameCounts = frameCounts
        self.transitionFrameCounts = transitionFrameCounts
        watchEngine()
    }

    private func watchEngine() {
        // Reads inside the first closure are "watched". When any of them is about to change,
        // `onChange` runs once, so we schedule another look right after the change lands.
        let (newPose, running, phase) = withObservationTracking {
            (Pose.for(phase: engine.phase, isRunning: engine.isRunning, isPaused: engine.isPaused),
             engine.isRunning,
             engine.phase)
        } onChange: { [weak self] in
            Task { @MainActor in self?.watchEngine() }
        }
        update(pose: newPose, running: running, phase: phase)
    }

    private func update(pose newPose: Pose, running: Bool, phase: Phase) {
        isRunning = running
        let oldPose = pose
        let isFirstLook = !hasStarted
        hasStarted = true

        if newPose == oldPose && !isFirstLook {
            // Same pose, e.g. a waiting break was started. A playing transition finishes
            // first and then starts the pose with this new running state.
            if transition == nil { startPose(force: false) }
            return
        }

        pose = newPose
        // A transition only for real phase changes: not at launch, not for Reset (→ idle).
        if !isFirstLook, phase != .idle,
           let next = Transition.between(oldPose, newPose),
           let count = transitionFrameCounts[next],
           animator.playOnce(frameCount: count, framesPerSecond: Transition.framesPerSecond,
                             completion: { [weak self] in self?.finishTransition() }) {
            transition = next
            isAnimating = false
        } else {
            transition = nil   // also cancels one that was mid-way (playOnce/stop cleared it)
            startPose(force: true)
        }
    }

    private func finishTransition() {
        transition = nil
        startPose(force: true)
    }

    /// Loops the current pose while running (if it has several frames), else shows frame 0.
    private func startPose(force: Bool) {
        let frameCount = frameCounts[pose] ?? 0
        let animate = isRunning && frameCount > 1
        guard force || animate != isAnimating else { return }   // only act on a real change
        isAnimating = animate
        if animate {
            animator.play(frameCount: frameCount, framesPerSecond: pose.framesPerSecond)
        } else {
            animator.stop()   // back to frame 0, timer off
        }
    }
}
