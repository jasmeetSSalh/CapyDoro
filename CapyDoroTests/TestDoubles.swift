//
//  TestDoubles.swift
//  CapyDoroTests
//
//  Fakes that stand in for the clock, macOS services and the 1-second timer,
//  so engine tests run instantly and never touch real notifications or sound.
//

import Foundation
@testable import CapyDoro

/// A clock that only moves when a test tells it to.
final class FakeClock {
    var now: Date

    init(_ start: Date = Date(timeIntervalSinceReferenceDate: 800_000_000)) {
        now = start
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

/// Records what the engine asked the notification service to do.
final class FakeNotifications: NotificationScheduling {
    private(set) var authorizationRequests = 0
    private(set) var scheduled: [(phase: Phase, date: Date)] = []
    private(set) var cancelCount = 0
    /// The alert that would still fire, or nil if nothing is pending.
    private(set) var pending: (phase: Phase, date: Date)?

    func requestAuthorizationIfNeeded() {
        authorizationRequests += 1
    }

    func scheduleEndOfPhase(_ phase: Phase, at date: Date) {
        scheduled.append((phase, date))
        pending = (phase, date)
    }

    func cancelPending() {
        cancelCount += 1
        pending = nil
    }
}

/// Counts chimes instead of playing them.
final class FakeSound: SoundPlaying {
    private(set) var chimeCount = 0

    func playChime() {
        chimeCount += 1
    }
}

/// A timer that never fires on its own; call `fire()` to simulate one tick.
final class FakeTicker: Ticking {
    private(set) var isActive = false
    private(set) var interval: TimeInterval?
    private var handler: (() -> Void)?

    func start(interval: TimeInterval, _ handler: @escaping () -> Void) {
        isActive = true
        self.interval = interval
        self.handler = handler
    }

    func stop() {
        isActive = false
        handler = nil
    }

    func fire() {
        handler?()
    }
}

/// A private UserDefaults that is wiped when the last test using it finishes.
final class TestDefaults {
    let suiteName = "CapyDoroTests.\(UUID().uuidString)"
    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

/// One engine wired to fakes. `relaunched()` simulates quitting and reopening
/// the app: same saved defaults and clock, fresh engine and services.
final class EngineHarness {
    let storage: TestDefaults
    let clock: FakeClock
    let notifications = FakeNotifications()
    let sound = FakeSound()
    let ticker = FakeTicker()
    let settings: SettingsStore
    let engine: PomodoroEngine

    init(storage: TestDefaults = TestDefaults(),
         clock: FakeClock = FakeClock(),
         configure: (SettingsStore) -> Void = { _ in }) {
        self.storage = storage
        self.clock = clock
        settings = SettingsStore(defaults: storage.defaults)
        configure(settings)
        engine = PomodoroEngine(
            settings: settings,
            notifications: notifications,
            sound: sound,
            ticker: ticker,
            now: { [clock] in clock.now }
        )
    }

    var defaults: UserDefaults { storage.defaults }

    func relaunched() -> EngineHarness {
        let next = EngineHarness(storage: storage, clock: clock)
        next.engine.restoreSavedState()
        return next
    }

    /// Jumps the clock to the current end date and lets the engine notice.
    func finishCurrentPhase() {
        if !engine.isRunning { engine.start() }
        guard let end = engine.endDate else { return }
        clock.now = end
        engine.tick()
    }
}
