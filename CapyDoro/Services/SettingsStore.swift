//
//  SettingsStore.swift
//  CapyDoro
//
//  User preferences. SKELETON: in-memory defaults only; saving to UserDefaults and
//  clamping to valid ranges arrive in M5.
//

import Foundation
import Observation

@Observable
final class SettingsStore {
    @ObservationIgnored let defaults: UserDefaults

    var focusMinutes = 25
    var shortBreakMinutes = 5
    var longBreakMinutes = 15
    var sessionsBeforeLongBreak = 4
    var soundEnabled = true
    var autoStartNext = false
    var animationsEnabled = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Length of a phase in seconds. Idle shows the focus length.
    func duration(for phase: Phase) -> Int {
        switch phase {
        case .idle, .focus: focusMinutes * 60
        case .shortBreak: shortBreakMinutes * 60
        case .longBreak: longBreakMinutes * 60
        }
    }
}
