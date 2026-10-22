//
//  NotificationService.swift
//  CapyDoro
//
//  Will show the "phase finished" alert via UserNotifications. PLACEHOLDER until M4:
//  it does nothing yet, but lets the app hand the engine a real object today.
//

import Foundation

final class NotificationService: NotificationScheduling {
    func requestAuthorizationIfNeeded() {}               // M4
    func scheduleEndOfPhase(_ phase: Phase, at date: Date) {}   // M4
    func cancelPending() {}                              // M4
}
