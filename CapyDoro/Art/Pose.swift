//
//  Pose.swift
//  CapyDoro
//
//  Which capybara drawing fits the timer's state. Raw values match the folder and file
//  names in Art/sprites (e.g. "walk" → walk_01.png …). Used by the animation (B3/B4).
//

enum Pose: String, CaseIterable {
    case stand    // idle, or a phase waiting for Start
    case walk     // focus running
    case jump     // the hop played between walk loops
    case sit      // short break
    case spring   // long break (hot spring)
    case sleep    // paused

    /// The pose for a timer state. Paused always sleeps, whatever the phase.
    static func `for`(phase: Phase, isRunning: Bool, isPaused: Bool) -> Pose {
        if isPaused { return .sleep }
        switch phase {
        case .idle: return .stand
        case .focus: return isRunning ? .walk : .stand
        case .shortBreak: return .sit
        case .longBreak: return .spring
        }
    }

    /// How fast multi-frame versions of this pose loop.
    var framesPerSecond: Double {
        switch self {
        case .walk: 8
        case .jump: 10
        case .stand, .sit, .spring, .sleep: 3
        }
    }
}
