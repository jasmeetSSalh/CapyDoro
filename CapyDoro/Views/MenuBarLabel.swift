//
//  MenuBarLabel.swift
//  CapyDoro
//
//  What you see in the menu bar: an icon and the time left, e.g. "24:13".
//  While focus runs, the icon is the walking/hopping capybara animation.
//

import SwiftUI

struct MenuBarLabel: View {
    // These are @Observable, so reading their properties here makes this view redraw
    // automatically whenever they change (every tick, every animation frame).
    let engine: PomodoroEngine
    let focusAnimation: FocusAnimationController
    let animator: CapybaraAnimator
    /// The focus loop's frames, loaded once at launch.
    let focusFrames: [NSImage]

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
        if focusAnimation.isWalking, let frame = currentFrame {
            Image(nsImage: frame)
                .renderingMode(.original)   // keep the capybara's colours, don't tint
        } else if engine.isPaused {
            Image(systemName: "pause.circle")
        } else if engine.phase.isBreak {
            Image(systemName: "cup.and.saucer")
        } else {
            Image(nsImage: Self.capybara)
        }
    }

    /// nil if the frames are missing, so the static icon shows instead of crashing.
    private var currentFrame: NSImage? {
        focusFrames.indices.contains(animator.frameIndex) ? focusFrames[animator.frameIndex] : nil
    }
}
