//
//  PomodoroEngine.swift
//  CapyDoro
//
//  The timer's brain: which phase we're in, when it ends, and what comes next.
//  No SwiftUI in here, so it can be tested on its own.
//
//  M2: countdown (start / pause / resume / reset). When a phase runs out it simply
//  returns to idle; M3 replaces that with the full focus → break cycle.
//

import Foundation
import Observation

@Observable
final class PomodoroEngine {
    private(set) var phase: Phase = .idle
    /// True only while time is actively counting down.
    private(set) var isRunning = false
    private(set) var isPaused = false
    /// When the current phase ends. Only set while running.
    private(set) var endDate: Date?
    /// Time left while paused (the source of truth when there is no end date).
    private(set) var remainingSeconds = 0
    private(set) var completedFocusCount = 0

    /// Bumped on every tick. The countdown is computed from the clock, which SwiftUI can't
    /// watch, so views read this to know they should redraw.
    private var tickVersion = 0

    // @ObservationIgnored: these never change, so views don't need to watch them.
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let notifications: NotificationScheduling
    @ObservationIgnored private let sound: SoundPlaying
    @ObservationIgnored private let ticker: Ticking
    @ObservationIgnored private let now: () -> Date

    init(settings: SettingsStore,
         notifications: NotificationScheduling,
         sound: SoundPlaying,
         ticker: Ticking,
         now: @escaping () -> Date = Date.init) {
        self.settings = settings
        self.notifications = notifications
        self.sound = sound
        self.ticker = ticker
        self.now = now
    }

    /// Seconds to show in the menu bar.
    var displayRemaining: Int {
        _ = tickVersion
        if let endDate {
            // Round partial seconds up, so a fresh 25-minute session shows 25:00, not 24:59.
            return max(0, Int(ceil(endDate.timeIntervalSince(now()))))
        }
        if phase == .idle {
            return settings.duration(for: .focus)
        }
        return remainingSeconds
    }

    // MARK: - Actions

    func start() {
        if isRunning { return }
        if isPaused {
            resume()
            return
        }
        if phase == .idle {
            phase = .focus
            remainingSeconds = settings.duration(for: .focus)
        }
        run()
    }

    func pause() {
        guard isRunning else { return }
        remainingSeconds = displayRemaining
        endDate = nil
        isRunning = false
        isPaused = true
        ticker.stop()
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        run()
    }

    func reset() {
        phase = .idle
        isRunning = false
        isPaused = false
        endDate = nil
        remainingSeconds = 0
        completedFocusCount = 0
        ticker.stop()
    }

    func skip() {}                // M3
    func restoreSavedState() {}   // M6

    /// Called every second while running (and on wake from sleep later).
    func tick() {
        guard isRunning, let endDate else { return }
        tickVersion += 1
        if now() >= endDate {
            finishPhase()
        }
    }

    // MARK: - Private

    /// Starts counting down `remainingSeconds` from now.
    private func run() {
        endDate = now().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        // `[weak self]` stops the timer from keeping the engine alive forever.
        ticker.start(interval: 1) { [weak self] in
            self?.tick()
        }
    }

    /// M2 placeholder: back to idle. M3 moves on to the next phase instead.
    private func finishPhase() {
        reset()
    }
}
