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

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(TimeFormatter.string(fromSeconds: engine.displayRemaining))
                .monospacedDigit()   // every digit gets the same width, so the item never jiggles
        }
    }

    /// SF Symbol for the current state (the capybara art replaces these later).
    private var iconName: String {
        if engine.isPaused { return "pause.circle" }
        return engine.phase.isBreak ? "cup.and.saucer" : "timer"
    }
}
