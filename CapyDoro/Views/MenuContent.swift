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
    let settings: SettingsStore
    /// SwiftUI's action for showing the Settings window (macOS 14+).
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        // Disabled Buttons show as greyed-out text: status lines.
        Button(statusLine) {}
            .disabled(true)
        Button("Sessions: \(engine.completedFocusCount) of \(settings.sessionsBeforeLongBreak)") {}
            .disabled(true)

        Divider()

        // Only show the action that makes sense right now.
        if engine.isRunning {
            Button("Pause") { engine.pause() }
        } else if engine.isPaused {
            Button("Resume") { engine.resume() }
        } else {
            Button(startTitle) { engine.start() }
        }

        if engine.phase != .idle {
            Button(engine.phase.isBreak ? "Skip Break" : "Skip Focus") { engine.skip() }
            Button("Reset") { engine.reset() }
        }

        #if DEBUG
        // `#if DEBUG` code exists only in builds run from Xcode, never in the shared app.
        if engine.isRunning {
            Button("Debug: Jump to 5 s left") { engine.debugJumpToEnd() }
        }
        #endif

        Divider()

        Button("Settings…") {
            // A menu bar app isn't "in front", so bring it forward first or the
            // window opens hidden behind other apps.
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")

        // An agent app has no Dock icon and no app menu, so this is the only way to quit.
        Button("Quit CapyDoro") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private var statusLine: String {
        if engine.phase == .idle { return "Ready to focus" }
        if engine.isPaused { return "\(engine.phase.displayName) · paused" }
        if !engine.isRunning { return "Up next: \(engine.phase.displayName)" }
        return engine.phase.displayName
    }

    /// "Start" from idle; "Start Short break" etc. when a prepared phase is waiting.
    private var startTitle: String {
        engine.phase == .idle ? "Start" : "Start \(engine.phase.displayName)"
    }
}
