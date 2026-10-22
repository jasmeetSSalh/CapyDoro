//
//  NotificationText.swift
//  CapyDoro
//
//  Words shown in the "phase finished" alert. Kept short so they fit in a banner.
//

enum NotificationText {
    static func title(forEndOf phase: Phase) -> String {
        switch phase {
        case .focus: "Focus session done"
        case .shortBreak: "Break's over"
        case .longBreak: "Long break's over"
        case .idle: "CapyDoro"
        }
    }

    static func body(forEndOf phase: Phase) -> String {
        switch phase {
        case .focus: "Nice work. Time for a break."
        case .shortBreak: "Back to focus when you're ready."
        case .longBreak: "Fully recharged. Start a fresh cycle."
        case .idle: "Ready when you are."
        }
    }
}
