//
//  MenuContent.swift
//  CapyDoro
//
//  The dropdown shown when you click the menu bar item. It only forwards taps to the
//  engine; all the timing logic lives there.
//

import SwiftUI

struct MenuContent: View {
    let engine: PomodoroEngine

    var body: some View {
        // A disabled Button shows as greyed-out text: a status line.
        Button(statusLine) {}
            .disabled(true)

        Divider()

        // Only show the action that makes sense right now.
        if engine.isRunning {
            Button("Pause") { engine.pause() }
        } else if engine.isPaused {
            Button("Resume") { engine.resume() }
        } else {
            Button("Start") { engine.start() }
        }

        if engine.phase != .idle {
            Button("Reset") { engine.reset() }
        }

        Divider()

        // An agent app has no Dock icon and no app menu, so this is the only way to quit.
        Button("Quit CapyDoro") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private var statusLine: String {
        if engine.phase == .idle { return "Ready to focus" }
        if engine.isPaused { return "\(engine.phase.displayName) · paused" }
        return engine.phase.displayName
    }
}
