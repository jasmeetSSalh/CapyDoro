//
//  EngineServices.swift
//  CapyDoro
//
//  The small "jobs" the engine needs done, written as protocols. The real app passes
//  real services; tests pass fakes. (A protocol is a list of methods a type promises to have.)
//

import Foundation

/// Shows the "phase finished" alert.
protocol NotificationScheduling: AnyObject {
    func requestAuthorizationIfNeeded()
    func scheduleEndOfPhase(_ phase: Phase, at date: Date)
    func cancelPending()
}

/// Plays the end-of-phase chime.
protocol SoundPlaying: AnyObject {
    func playChime()
}

/// A repeating timer (the 1-second tick, or the sprite frame timer).
protocol Ticking: AnyObject {
    func start(interval: TimeInterval, _ handler: @escaping () -> Void)
    func stop()
}
