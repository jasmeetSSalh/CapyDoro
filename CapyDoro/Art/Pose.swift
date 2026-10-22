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
    case nap      // short break: dozing, z's floating up
    case spring   // long break: floating in a hot spring
    case sleep    // paused: asleep, still

    /// The pose for a timer state. Paused always sleeps, whatever the phase.
    static func `for`(phase: Phase, isRunning: Bool, isPaused: Bool) -> Pose {
        if isPaused { return .sleep }
        switch phase {
        case .idle: return .stand
        case .focus: return isRunning ? .walk : .stand
        case .shortBreak: return .nap
        case .longBreak: return .spring
        }
    }

    /// How fast multi-frame versions of this pose loop.
    var framesPerSecond: Double {
        switch self {
        case .walk: 8
        case .jump: 10
        case .spring: 4   // 16-frame drift across the pool = 4 s
        case .stand, .nap, .sleep: 3
        }
    }
}
