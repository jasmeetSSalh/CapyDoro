//
//  Transition.swift
//  CapyDoro
//
//  Short scenes (under a second) played once in the menu bar when the phase changes,
//  before the new pose takes over. Raw values match the sprite names ("flop_01" …).
//

enum Transition: String, CaseIterable {
    case flop     // focus → short break: flops down for a nap
    case dive     // focus → long break: hops and splashes into the pool
    case wake     // short break → focus: stretches up
    case emerge   // long break → focus: climbs out and shakes off

    static let framesPerSecond: Double = 10

    /// The transition between two poses, or nil to switch instantly (pause, resume, reset…).
    static func between(_ from: Pose, _ to: Pose) -> Transition? {
        switch (from, to) {
        case (.walk, .nap): .flop
        case (.walk, .spring): .dive
        case (.nap, .stand), (.nap, .walk): .wake
        case (.spring, .stand), (.spring, .walk): .emerge
        default: nil
        }
    }
}
