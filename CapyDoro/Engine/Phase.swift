//
//  Phase.swift
//  CapyDoro
//
//  The four states of the timer. Raw values are saved to UserDefaults, so never rename them.
//

enum Phase: String, Codable, CaseIterable {
    case idle
    case focus
    case shortBreak
    case longBreak

    var isBreak: Bool {
        self == .shortBreak || self == .longBreak
    }

    /// Short name shown in the dropdown.
    var displayName: String {
        switch self {
        case .idle: "Ready"
        case .focus: "Focus"
        case .shortBreak: "Short break"
        case .longBreak: "Long break"
        }
    }
}
