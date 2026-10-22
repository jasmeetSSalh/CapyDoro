//
//  SettingsStore.swift
//  CapyDoro
//
//  User preferences, saved in UserDefaults (a small key-value store macOS keeps per app).
//  Every value has a default and numbers are clamped to a safe range, both when you
//  change them and when they're loaded (in case the saved file holds something odd).
//

import Foundation
import Observation

@Observable
final class SettingsStore {
    static let focusRange = 1...120
    static let breakRange = 1...60
    static let sessionsRange = 2...8

    @ObservationIgnored let defaults: UserDefaults

    /// The values below are read straight from UserDefaults, which SwiftUI can't watch.
    /// Bumping this on every write tells views to redraw.
    private var version = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // `get` reads the saved value (or the default); `set` clamps and saves it.

    var focusMinutes: Int {
        get { int("focusMinutes", default: 25, in: Self.focusRange) }
        set { setInt(newValue, "focusMinutes", in: Self.focusRange) }
    }

    var shortBreakMinutes: Int {
        get { int("shortBreakMinutes", default: 5, in: Self.breakRange) }
        set { setInt(newValue, "shortBreakMinutes", in: Self.breakRange) }
    }

    var longBreakMinutes: Int {
        get { int("longBreakMinutes", default: 15, in: Self.breakRange) }
        set { setInt(newValue, "longBreakMinutes", in: Self.breakRange) }
    }

    var sessionsBeforeLongBreak: Int {
        get { int("sessionsBeforeLongBreak", default: 4, in: Self.sessionsRange) }
        set { setInt(newValue, "sessionsBeforeLongBreak", in: Self.sessionsRange) }
    }

    var soundEnabled: Bool {
        get { bool("soundEnabled", default: true) }
        set { setBool(newValue, "soundEnabled") }
    }

    var autoStartNext: Bool {
        get { bool("autoStartNext", default: false) }
        set { setBool(newValue, "autoStartNext") }
    }

    var animationsEnabled: Bool {
        get { bool("animationsEnabled", default: true) }
        set { setBool(newValue, "animationsEnabled") }
    }

    /// Length of a phase in seconds. Idle shows the focus length.
    func duration(for phase: Phase) -> Int {
        switch phase {
        case .idle, .focus: focusMinutes * 60
        case .shortBreak: shortBreakMinutes * 60
        case .longBreak: longBreakMinutes * 60
        }
    }

    // MARK: - Private

    private func int(_ key: String, default fallback: Int, in range: ClosedRange<Int>) -> Int {
        _ = version
        // `as? Int` gives nil when nothing is saved yet; `??` then uses the default.
        let stored = defaults.object(forKey: key) as? Int ?? fallback
        return Self.clamp(stored, to: range)
    }

    private func setInt(_ value: Int, _ key: String, in range: ClosedRange<Int>) {
        defaults.set(Self.clamp(value, to: range), forKey: key)
        version += 1
    }

    private func bool(_ key: String, default fallback: Bool) -> Bool {
        _ = version
        return defaults.object(forKey: key) as? Bool ?? fallback
    }

    private func setBool(_ value: Bool, _ key: String) {
        defaults.set(value, forKey: key)
        version += 1
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
