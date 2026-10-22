//
//  MenuBarLabel.swift
//  CapyDoro
//
//  What you see in the menu bar: the capybara in its current pose (or a transition between
//  poses) and the time left, e.g. "24:13".
//

import SwiftUI

struct MenuBarLabel: View {
    // These are @Observable, so reading their properties here makes this view redraw
    // automatically whenever they change (every tick, every animation frame, every pose).
    let engine: PomodoroEngine
    let poseAnimation: PoseAnimationController
    let animator: CapybaraAnimator
    /// Every pose's and transition's frames, loaded once at launch.
    let poseFrames: [Pose: [NSImage]]
    let transitionFrames: [Transition: [NSImage]]

    /// Loaded once and shared (`static`), not reloaded on every tick.
    private static let capybara = ArtCatalog.menuBarIcon()

    var body: some View {
        HStack(spacing: 4) {
            icon
            Text(TimeFormatter.string(fromSeconds: engine.displayRemaining))
                .monospacedDigit()   // every digit gets the same width, so the item never jiggles
        }
    }

    /// `@ViewBuilder` lets one property return different kinds of views from an `if`.
    @ViewBuilder
    private var icon: some View {
        if let frame = currentFrame {
            Image(nsImage: frame)
                .renderingMode(.original)   // keep the capybara's colours, don't tint
        } else if engine.isPaused {         // fallbacks if a pose's art is ever missing
            Image(systemName: "pause.circle")
        } else if engine.phase.isBreak {
            Image(systemName: "cup.and.saucer")
        } else {
            Image(nsImage: Self.capybara)
        }
    }

    /// The frame to show: the playing transition's, else the current pose's; nil if that
    /// art is missing. `%` keeps the index in range for the instant between a change and
    /// the animator restarting at frame 0.
    private var currentFrame: NSImage? {
        let frames: [NSImage]?
        if let transition = poseAnimation.transition {
            frames = transitionFrames[transition]
        } else {
            frames = poseFrames[poseAnimation.pose]
        }
        guard let frames, !frames.isEmpty else { return nil }
        return frames[animator.frameIndex % frames.count]
    }
}
