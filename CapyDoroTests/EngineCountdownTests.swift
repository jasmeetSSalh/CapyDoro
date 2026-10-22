//
//  EngineCountdownTests.swift
//  CapyDoroTests
//
//  M2: real countdown. Start / Pause / Resume / Reset, end-date math, and the
//  tick timer running only while the timer is running.
//

import Foundation
import Testing
@testable import CapyDoro

@Suite("Engine – countdown (M2)")
struct EngineCountdownTests {
    let h = EngineHarness()

    @Test("A new engine is idle and shows the focus length")
    func startsIdle() {
        #expect(h.engine.phase == .idle)
        #expect(!h.engine.isRunning)
        #expect(!h.engine.isPaused)
        #expect(h.engine.endDate == nil)
        #expect(h.engine.completedFocusCount == 0)
        #expect(h.engine.displayRemaining == 25 * 60)
        #expect(!h.ticker.isActive)
    }

    @Test("Start from idle begins a full focus session")
    func startFromIdle() {
        h.engine.start()
        #expect(h.engine.phase == .focus)
        #expect(h.engine.isRunning)
        #expect(h.engine.endDate == h.clock.now.addingTimeInterval(25 * 60))
        #expect(h.engine.displayRemaining == 25 * 60)
    }

    @Test("Starting turns on a 1-second tick timer")
    func startStartsTicker() {
        h.engine.start()
        #expect(h.ticker.isActive)
        #expect(h.ticker.interval == 1)
    }

    @Test("Remaining time is computed from the end date, not counted down")
    func remainingFromEndDate() {
        h.engine.start()
        h.clock.advance(by: 60)
        #expect(h.engine.displayRemaining == 24 * 60)
        h.clock.advance(by: 0.4)   // partial seconds round up, so 24:00 shows for a full second
        #expect(h.engine.displayRemaining == 24 * 60)
        h.clock.advance(by: 0.6)
        #expect(h.engine.displayRemaining == 24 * 60 - 1)
    }

    @Test("Ticking before the end date does not change phase")
    func tickBeforeEnd() {
        h.engine.start()
        h.clock.advance(by: 25 * 60 - 1)
        h.engine.tick()
        #expect(h.engine.phase == .focus)
        #expect(h.engine.isRunning)
    }

    @Test("Pause freezes the remaining time and stops the tick timer")
    func pause() {
        h.engine.start()
        h.clock.advance(by: 100)
        h.engine.pause()

        #expect(!h.engine.isRunning)
        #expect(h.engine.isPaused)
        #expect(h.engine.endDate == nil)
        #expect(h.engine.remainingSeconds == 1400)
        #expect(!h.ticker.isActive)

        h.clock.advance(by: 500)
        #expect(h.engine.displayRemaining == 1400)
    }

    @Test("Resume sets a new end date = now + remaining")
    func resume() {
        h.engine.start()
        h.clock.advance(by: 100)
        h.engine.pause()
        h.clock.advance(by: 500)
        h.engine.resume()

        #expect(h.engine.isRunning)
        #expect(!h.engine.isPaused)
        #expect(h.engine.endDate == h.clock.now.addingTimeInterval(1400))
        #expect(h.engine.displayRemaining == 1400)
        #expect(h.ticker.isActive)
    }

    @Test("Start while paused behaves like Resume")
    func startWhilePaused() {
        h.engine.start()
        h.clock.advance(by: 100)
        h.engine.pause()
        h.engine.start()
        #expect(h.engine.phase == .focus)
        #expect(h.engine.endDate == h.clock.now.addingTimeInterval(1400))
    }

    @Test("Start while already running changes nothing")
    func startWhileRunning() {
        h.engine.start()
        let end = h.engine.endDate
        h.clock.advance(by: 10)
        h.engine.start()
        #expect(h.engine.endDate == end)
    }

    @Test("Pause when not running does nothing")
    func pauseWhenIdle() {
        h.engine.pause()
        #expect(h.engine.phase == .idle)
        #expect(!h.engine.isPaused)
    }

    @Test("Resume when not paused does nothing")
    func resumeWhenNotPaused() {
        h.engine.resume()
        #expect(h.engine.phase == .idle)
        #expect(!h.engine.isRunning)
    }

    @Test("Reset while running returns to idle and stops everything")
    func resetWhileRunning() {
        h.engine.start()
        h.clock.advance(by: 300)
        h.engine.reset()

        #expect(h.engine.phase == .idle)
        #expect(!h.engine.isRunning)
        #expect(!h.engine.isPaused)
        #expect(h.engine.endDate == nil)
        #expect(h.engine.displayRemaining == 25 * 60)
        #expect(!h.ticker.isActive)
    }

    @Test("Reset while paused returns to idle")
    func resetWhilePaused() {
        h.engine.start()
        h.engine.pause()
        h.engine.reset()
        #expect(h.engine.phase == .idle)
        #expect(!h.engine.isPaused)
    }

    @Test("Changing focus length while idle updates the display")
    func idleFollowsSettings() {
        h.settings.focusMinutes = 50
        #expect(h.engine.displayRemaining == 50 * 60)
    }

    @Test("Changing focus length does not alter a running session")
    func runningIgnoresSettings() {
        h.engine.start()
        let end = h.engine.endDate
        h.settings.focusMinutes = 50
        #expect(h.engine.endDate == end)
        #expect(h.engine.displayRemaining == 25 * 60)
    }
}
