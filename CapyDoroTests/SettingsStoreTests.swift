//
//  SettingsStoreTests.swift
//  CapyDoroTests
//
//  M5: settings live in UserDefaults, have sensible defaults, and are clamped to safe ranges.
//

import Foundation
import Testing
@testable import CapyDoro

@Suite("SettingsStore")
struct SettingsStoreTests {
    let storage = TestDefaults()

    @Test("A fresh install uses the plan's defaults")
    func defaults() {
        let settings = SettingsStore(defaults: storage.defaults)
        #expect(settings.focusMinutes == 25)
        #expect(settings.shortBreakMinutes == 5)
        #expect(settings.longBreakMinutes == 15)
        #expect(settings.sessionsBeforeLongBreak == 4)
        #expect(settings.soundEnabled == true)
        #expect(settings.autoStartNext == false)
        #expect(settings.animationsEnabled == true)
    }

    @Test("Durations are returned in seconds; idle shows the focus length")
    func durations() {
        let settings = SettingsStore(defaults: storage.defaults)
        #expect(settings.duration(for: .focus) == 25 * 60)
        #expect(settings.duration(for: .shortBreak) == 5 * 60)
        #expect(settings.duration(for: .longBreak) == 15 * 60)
        #expect(settings.duration(for: .idle) == 25 * 60)
    }

    @Test("Changes survive a relaunch")
    func persists() {
        let settings = SettingsStore(defaults: storage.defaults)
        settings.focusMinutes = 50
        settings.shortBreakMinutes = 10
        settings.longBreakMinutes = 30
        settings.sessionsBeforeLongBreak = 3
        settings.soundEnabled = false
        settings.autoStartNext = true
        settings.animationsEnabled = false

        let reloaded = SettingsStore(defaults: storage.defaults)
        #expect(reloaded.focusMinutes == 50)
        #expect(reloaded.shortBreakMinutes == 10)
        #expect(reloaded.longBreakMinutes == 30)
        #expect(reloaded.sessionsBeforeLongBreak == 3)
        #expect(reloaded.soundEnabled == false)
        #expect(reloaded.autoStartNext == true)
        #expect(reloaded.animationsEnabled == false)
    }

    @Test("Values are saved under the key names from the plan")
    func keyNames() {
        let settings = SettingsStore(defaults: storage.defaults)
        settings.focusMinutes = 40
        settings.soundEnabled = false
        #expect(storage.defaults.integer(forKey: "focusMinutes") == 40)
        #expect(storage.defaults.object(forKey: "soundEnabled") as? Bool == false)
    }

    @Test("Focus minutes are clamped to 1–120", arguments: [(0, 1), (-5, 1), (1, 1), (120, 120), (121, 120), (999, 120)])
    func clampFocus(input: Int, expected: Int) {
        let settings = SettingsStore(defaults: storage.defaults)
        settings.focusMinutes = input
        #expect(settings.focusMinutes == expected)
    }

    @Test("Break minutes are clamped to 1–60", arguments: [(0, 1), (60, 60), (61, 60)])
    func clampBreaks(input: Int, expected: Int) {
        let settings = SettingsStore(defaults: storage.defaults)
        settings.shortBreakMinutes = input
        settings.longBreakMinutes = input
        #expect(settings.shortBreakMinutes == expected)
        #expect(settings.longBreakMinutes == expected)
    }

    @Test("Sessions before a long break are clamped to 2–8", arguments: [(1, 2), (2, 2), (8, 8), (9, 8)])
    func clampSessions(input: Int, expected: Int) {
        let settings = SettingsStore(defaults: storage.defaults)
        settings.sessionsBeforeLongBreak = input
        #expect(settings.sessionsBeforeLongBreak == expected)
    }

    @Test("The clamped value is what gets saved")
    func savesClampedValue() {
        SettingsStore(defaults: storage.defaults).focusMinutes = 500
        #expect(SettingsStore(defaults: storage.defaults).focusMinutes == 120)
    }

    @Test("Bad values already on disk are clamped when loaded")
    func clampsOnLoad() {
        storage.defaults.set(999, forKey: "focusMinutes")
        storage.defaults.set(0, forKey: "sessionsBeforeLongBreak")
        let settings = SettingsStore(defaults: storage.defaults)
        #expect(settings.focusMinutes == 120)
        #expect(settings.sessionsBeforeLongBreak == 2)
    }
}
