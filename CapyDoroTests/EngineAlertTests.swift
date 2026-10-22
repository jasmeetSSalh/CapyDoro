//
//  EngineAlertTests.swift
//  CapyDoroTests
//
//  M4: alerts. Permission on Start, a notification scheduled for the end date,
//  cancelled on pause/reset/skip (no ghost alerts), and the chime.
//

import Foundation
import Testing
@testable import CapyDoro

@Suite("Engine – alerts (M4)")
struct EngineAlertTests {
    let h = EngineHarness()

    @Test("The first Start asks for notification permission")
    func startRequestsPermission() {
        #expect(h.notifications.authorizationRequests == 0)
        h.engine.start()
        #expect(h.notifications.authorizationRequests >= 1)
    }

    @Test("Start schedules an alert for the exact end date")
    func startSchedules() {
        h.engine.start()
        let pending = h.notifications.pending
        #expect(pending?.phase == .focus)
        #expect(pending?.date == h.engine.endDate)
    }

    @Test("Pause cancels the pending alert")
    func pauseCancels() {
        h.engine.start()
        h.engine.pause()
        #expect(h.notifications.pending == nil)
    }

    @Test("Resume schedules a new alert at the new end date")
    func resumeReschedules() {
        h.engine.start()
        h.clock.advance(by: 100)
        h.engine.pause()
        h.clock.advance(by: 1000)
        h.engine.resume()
        #expect(h.notifications.pending?.date == h.clock.now.addingTimeInterval(1400))
    }

    @Test("Reset cancels the pending alert")
    func resetCancels() {
        h.engine.start()
        h.engine.reset()
        #expect(h.notifications.pending == nil)
    }

    @Test("Skip cancels the skipped phase's alert")
    func skipCancels() {
        h.engine.start()
        h.engine.skip()
        #expect(h.notifications.pending == nil)
    }

    @Test("With autoStartNext, the next phase gets its own alert")
    func autoStartSchedulesNext() {
        let h = EngineHarness { $0.autoStartNext = true }
        h.finishCurrentPhase()
        #expect(h.notifications.pending?.phase == .shortBreak)
        #expect(h.notifications.pending?.date == h.clock.now.addingTimeInterval(5 * 60))
    }

    @Test("A waiting phase has no alert until it is started")
    func waitingPhaseHasNoAlert() {
        h.finishCurrentPhase()
        #expect(h.notifications.pending == nil)
    }

    @Test("A phase ending on its own plays the chime when sound is on")
    func chimeWhenEnabled() {
        h.finishCurrentPhase()
        #expect(h.sound.chimeCount == 1)
    }

    @Test("No chime when sound is off")
    func noChimeWhenDisabled() {
        let h = EngineHarness { $0.soundEnabled = false }
        h.finishCurrentPhase()
        #expect(h.sound.chimeCount == 0)
    }

    @Test("Skipping is silent (you pressed the button, you know)")
    func skipIsSilent() {
        h.engine.start()
        h.engine.skip()
        #expect(h.sound.chimeCount == 0)
    }

    @Test("Extra ticks after the end do not chime again")
    func chimeOnce() {
        h.engine.start()
        h.clock.advance(by: 2 * 60 * 60)
        h.engine.tick()
        h.engine.tick()
        #expect(h.sound.chimeCount == 1)
    }
}

@Suite("Notification text (M4)")
struct NotificationTextTests {

    @Test("Each ending phase has a short title and body", arguments: [Phase.focus, .shortBreak, .longBreak])
    func textExists(phase: Phase) {
        #expect(!NotificationText.title(forEndOf: phase).isEmpty)
        #expect(!NotificationText.body(forEndOf: phase).isEmpty)
        #expect(NotificationText.title(forEndOf: phase).count <= 40)
    }

    @Test("Focus ending and a break ending say different things")
    func focusAndBreakDiffer() {
        #expect(NotificationText.title(forEndOf: .focus) != NotificationText.title(forEndOf: .shortBreak))
    }
}
