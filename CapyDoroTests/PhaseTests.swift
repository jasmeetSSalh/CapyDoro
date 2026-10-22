//
//  PhaseTests.swift
//  CapyDoroTests
//
//  M2/M3: the Phase enum. Raw values are saved to UserDefaults, so they must never change.
//

import Testing
@testable import CapyDoro

@Suite("Phase")
struct PhaseTests {

    @Test("Raw values match the saved strings from the plan")
    func rawValues() {
        #expect(Phase.idle.rawValue == "idle")
        #expect(Phase.focus.rawValue == "focus")
        #expect(Phase.shortBreak.rawValue == "shortBreak")
        #expect(Phase.longBreak.rawValue == "longBreak")
    }

    @Test("Only the two break phases count as breaks")
    func isBreak() {
        #expect(Phase.shortBreak.isBreak)
        #expect(Phase.longBreak.isBreak)
        #expect(!Phase.focus.isBreak)
        #expect(!Phase.idle.isBreak)
    }

    @Test("Every phase has a short name for the menu", arguments: Phase.allCases)
    func displayName(phase: Phase) {
        #expect(!phase.displayName.isEmpty)
        #expect(phase.displayName.count <= 20)
    }
}
