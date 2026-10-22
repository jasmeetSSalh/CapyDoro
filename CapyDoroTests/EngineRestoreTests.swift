//
//  EngineRestoreTests.swift
//  CapyDoroTests
//
//  M6: the timer survives quitting/crashing. State is saved to UserDefaults under
//  the plan's keys and restored on the next launch.
//

import Foundation
import Testing
@testable import CapyDoro

@Suite("Engine – restore after relaunch (M6)")
struct EngineRestoreTests {
    let h = EngineHarness()

    @Test("A fresh install restores to idle")
    func freshInstall() {
        let next = h.relaunched()
        #expect(next.engine.phase == .idle)
        #expect(!next.engine.isRunning)
    }

    @Test("Running state is saved under the plan's keys")
    func savedKeys() {
        h.engine.start()
        #expect(h.defaults.string(forKey: "currentPhase") == "focus")
        #expect(h.defaults.object(forKey: "currentEndDate") as? Date == h.engine.endDate)
    }

    @Test("A session still in progress keeps running after relaunch")
    func restoresRunning() {
        h.engine.start()
        let end = h.engine.endDate
        h.clock.advance(by: 100)

        let next = h.relaunched()
        #expect(next.engine.phase == .focus)
        #expect(next.engine.isRunning)
        #expect(next.engine.endDate == end)
        #expect(next.engine.displayRemaining == 1400)
        #expect(next.ticker.isActive)
        #expect(next.notifications.pending?.date == end)
    }

    @Test("A session that ended while the app was closed is treated as ended (once)")
    func restoresEndedPhase() {
        h.engine.start()
        h.clock.advance(by: 2 * 60 * 60)

        let next = h.relaunched()
        #expect(next.engine.phase == .shortBreak)
        #expect(next.engine.completedFocusCount == 1)
        #expect(!next.engine.isRunning)
        #expect(next.sound.chimeCount == 0)   // the system already showed the alert
    }

    @Test("After relaunch an ended phase waits for Start even if autoStartNext is on")
    func restoredEndedPhaseWaits() {
        h.settings.autoStartNext = true
        h.engine.start()
        h.clock.advance(by: 2 * 60 * 60)

        let next = h.relaunched()
        #expect(next.engine.phase == .shortBreak)
        #expect(!next.engine.isRunning)
        #expect(next.engine.displayRemaining == 5 * 60)
    }

    @Test("A paused session stays paused with the same time left")
    func restoresPaused() {
        h.engine.start()
        h.clock.advance(by: 100)
        h.engine.pause()
        h.clock.advance(by: 99_999)

        let next = h.relaunched()
        #expect(next.engine.phase == .focus)
        #expect(next.engine.isPaused)
        #expect(!next.engine.isRunning)
        #expect(next.engine.displayRemaining == 1400)
        #expect(!next.ticker.isActive)
    }

    @Test("A prepared phase waiting for Start is restored")
    func restoresWaiting() {
        h.finishCurrentPhase()

        let next = h.relaunched()
        #expect(next.engine.phase == .shortBreak)
        #expect(!next.engine.isRunning)
        #expect(!next.engine.isPaused)
        #expect(next.engine.displayRemaining == 5 * 60)
    }

    @Test("The completed-focus count survives relaunch")
    func restoresCount() {
        for _ in 1...4 { h.finishCurrentPhase() }   // 2 focuses + 2 short breaks
        let next = h.relaunched()
        #expect(next.engine.completedFocusCount == 2)
    }

    @Test("Reset clears the saved session")
    func resetClearsSaved() {
        h.engine.start()
        h.engine.reset()
        let next = h.relaunched()
        #expect(next.engine.phase == .idle)
        #expect(next.engine.completedFocusCount == 0)
    }
}
