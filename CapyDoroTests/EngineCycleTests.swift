//
//  EngineCycleTests.swift
//  CapyDoroTests
//
//  M3: full cycle. Focus → short break ×3, 4th focus → long break, count reset,
//  Skip rules, sleep handling, and autoStartNext.
//

import Foundation
import Testing
@testable import CapyDoro

@Suite("Engine – full cycle (M3)")
struct EngineCycleTests {

    @Test("Finishing focus moves to a short break and counts the session")
    func focusEndsToShortBreak() {
        let h = EngineHarness()
        h.finishCurrentPhase()
        #expect(h.engine.phase == .shortBreak)
        #expect(h.engine.completedFocusCount == 1)
    }

    @Test("Focus ×1, ×2, ×3 → short break; ×4 → long break")
    func fourthFocusIsLong() {
        let h = EngineHarness()
        var breaks: [Phase] = []
        for _ in 1...4 {
            h.finishCurrentPhase()          // focus ends
            breaks.append(h.engine.phase)
            if breaks.count < 4 { h.finishCurrentPhase() }   // break ends
        }
        #expect(breaks == [.shortBreak, .shortBreak, .shortBreak, .longBreak])
        #expect(h.engine.completedFocusCount == 4)
    }

    @Test("After a long break the count resets to 0 and focus is next")
    func longBreakResetsCount() {
        let h = EngineHarness()
        for _ in 1...8 { h.finishCurrentPhase() }   // 4 focus + 4 breaks (last one long)
        #expect(h.engine.phase == .focus)
        #expect(h.engine.completedFocusCount == 0)
    }

    @Test("The whole cycle visits phases in order")
    func fullSequence() {
        let h = EngineHarness()
        h.engine.start()
        var seen: [Phase] = [h.engine.phase]
        for _ in 1...8 {
            h.finishCurrentPhase()
            seen.append(h.engine.phase)
        }
        #expect(seen == [.focus, .shortBreak, .focus, .shortBreak, .focus, .shortBreak, .focus, .longBreak, .focus])
    }

    @Test("sessionsBeforeLongBreak = 2 gives a long break after the 2nd focus")
    func customLongBreakInterval() {
        let h = EngineHarness { $0.sessionsBeforeLongBreak = 2 }
        h.finishCurrentPhase()
        #expect(h.engine.phase == .shortBreak)
        h.finishCurrentPhase()
        h.finishCurrentPhase()
        #expect(h.engine.phase == .longBreak)
    }

    @Test("Breaks use their configured lengths")
    func breakLengths() {
        let h = EngineHarness {
            $0.shortBreakMinutes = 7
            $0.longBreakMinutes = 20
            $0.sessionsBeforeLongBreak = 2
        }
        h.finishCurrentPhase()
        #expect(h.engine.displayRemaining == 7 * 60)
        h.finishCurrentPhase()
        h.finishCurrentPhase()
        #expect(h.engine.displayRemaining == 20 * 60)
    }

    // MARK: Skip

    @Test("Skipping focus does NOT count it, and goes to a short break")
    func skipFocus() {
        let h = EngineHarness()
        h.engine.start()
        h.engine.skip()
        #expect(h.engine.phase == .shortBreak)
        #expect(h.engine.completedFocusCount == 0)
    }

    @Test("Skipping focus never earns a long break")
    func skipFocusNeverLong() {
        let h = EngineHarness()
        for _ in 1...3 { h.finishCurrentPhase(); h.finishCurrentPhase() }   // 3 counted focuses
        h.engine.start()
        h.engine.skip()                                                       // 4th is skipped
        #expect(h.engine.phase == .shortBreak)
        #expect(h.engine.completedFocusCount == 3)
    }

    @Test("Skipping a short break moves to focus and keeps the count")
    func skipShortBreak() {
        let h = EngineHarness()
        h.finishCurrentPhase()
        h.engine.skip()
        #expect(h.engine.phase == .focus)
        #expect(h.engine.completedFocusCount == 1)
    }

    @Test("Skipping a long break resets the count like finishing it")
    func skipLongBreak() {
        let h = EngineHarness { $0.sessionsBeforeLongBreak = 2 }
        h.finishCurrentPhase(); h.finishCurrentPhase(); h.finishCurrentPhase()
        #expect(h.engine.phase == .longBreak)
        h.engine.skip()
        #expect(h.engine.phase == .focus)
        #expect(h.engine.completedFocusCount == 0)
    }

    @Test("Skip works while paused and clears the paused state")
    func skipWhilePaused() {
        let h = EngineHarness()
        h.engine.start()
        h.engine.pause()
        h.engine.skip()
        #expect(h.engine.phase == .shortBreak)
        #expect(!h.engine.isPaused)
    }

    @Test("Skip does nothing while idle")
    func skipWhenIdle() {
        let h = EngineHarness()
        h.engine.skip()
        #expect(h.engine.phase == .idle)
    }

    // MARK: Sleep / missed ticks

    @Test("A tick long after the end date (Mac was asleep) transitions exactly once")
    func longSleepTransitionsOnce() {
        let h = EngineHarness()
        h.engine.start()
        h.clock.advance(by: 3 * 60 * 60)   // 3 hours
        h.engine.tick()
        #expect(h.engine.phase == .shortBreak)
        #expect(h.engine.completedFocusCount == 1)

        h.engine.tick()
        h.engine.tick()
        #expect(h.engine.phase == .shortBreak)
        #expect(h.engine.completedFocusCount == 1)
    }

    @Test("The tick timer drives transitions")
    func tickerFiresTick() {
        let h = EngineHarness()
        h.engine.start()
        h.clock.advance(by: 25 * 60)
        h.ticker.fire()
        #expect(h.engine.phase == .shortBreak)
    }

    // MARK: autoStartNext

    @Test("autoStartNext off: the next phase is prepared and waits for Start")
    func autoStartOff() {
        let h = EngineHarness()
        h.finishCurrentPhase()
        #expect(h.engine.phase == .shortBreak)
        #expect(!h.engine.isRunning)
        #expect(!h.engine.isPaused)
        #expect(h.engine.endDate == nil)
        #expect(h.engine.displayRemaining == 5 * 60)
        #expect(!h.ticker.isActive)

        h.clock.advance(by: 600)            // waiting doesn't eat into the break
        #expect(h.engine.displayRemaining == 5 * 60)

        h.engine.start()
        #expect(h.engine.isRunning)
        #expect(h.engine.endDate == h.clock.now.addingTimeInterval(5 * 60))
    }

    @Test("autoStartNext on: the next phase starts immediately")
    func autoStartOn() {
        let h = EngineHarness { $0.autoStartNext = true }
        h.finishCurrentPhase()
        #expect(h.engine.phase == .shortBreak)
        #expect(h.engine.isRunning)
        #expect(h.engine.endDate == h.clock.now.addingTimeInterval(5 * 60))
        #expect(h.ticker.isActive)
    }

    @Test("autoStartNext after a long sleep starts the break from now, not from the old end")
    func autoStartAfterSleep() {
        let h = EngineHarness { $0.autoStartNext = true }
        h.engine.start()
        h.clock.advance(by: 3 * 60 * 60)
        h.engine.tick()
        #expect(h.engine.phase == .shortBreak)
        #expect(h.engine.endDate == h.clock.now.addingTimeInterval(5 * 60))
    }

    @Test("A changed focus length applies to the next focus session")
    func durationAppliesNextPhase() {
        let h = EngineHarness()
        h.engine.start()
        h.settings.focusMinutes = 50
        h.finishCurrentPhase()   // focus (still 25 min) ends
        h.finishCurrentPhase()   // break ends
        #expect(h.engine.phase == .focus)
        #expect(h.engine.displayRemaining == 50 * 60)
    }
}
