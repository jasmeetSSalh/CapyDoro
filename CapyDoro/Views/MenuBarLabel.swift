//
//  MenuBarLabel.swift
//  CapyDoro
//
//  What you see in the menu bar: an icon and the time left, e.g. "24:13".
//

import SwiftUI

struct MenuBarLabel: View {
    // The engine is @Observable, so reading its properties here makes this view
    // redraw automatically whenever they change (every tick while running).
    let engine: PomodoroEngine

    /// Loaded once and shared (`static`), not reloaded on every tick.
    private static let capybara = ArtCatalog.menuBarIcon()

    var body: some View {
        HStack(spacing: 4) {
            icon
            Text(TimeFormatter.string(fromSeconds: engine.displayRemaining))
                .monospacedDigit()   // every digit gets the same width, so the item never jiggles
        }
    }

    /// The capybara normally; SF Symbols for paused and breaks until the B4 poses exist.
    /// `@ViewBuilder` lets one property return different kinds of views from an `if`.
    @ViewBuilder
    private var icon: some View {
        if engine.isPaused {
            Image(systemName: "pause.circle")
        } else if engine.phase.isBreak {
            Image(systemName: "cup.and.saucer")
        } else {
            Image(nsImage: Self.capybara)
        }
    }
}
