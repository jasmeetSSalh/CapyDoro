//
//  PomodoroEngine.swift
//  CapyDoro
//
//  The timer's brain: which phase we're in, when it ends, and what comes next.
//  No SwiftUI in here, so it can be tested on its own.
//
//  Cycle: focus → short break, and every Nth counted focus → long break (N =
//  sessionsBeforeLongBreak). Finishing or skipping a long break resets the count.
//  A skipped focus is not counted.
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

    /// Ends the current phase now, without counting a skipped focus.
    func skip() {
        guard phase != .idle else { return }
        advance(countFocus: false)
    }

    func restoreSavedState() {}   // M6

    #if DEBUG
    /// Testing aid (debug builds only): makes the running phase end in a few seconds.
    func debugJumpToEnd(secondsLeft: Int = 5) {
        guard isRunning else { return }
        endDate = now().addingTimeInterval(TimeInterval(secondsLeft))
    }
    #endif

    /// Called every second while running (and on wake from sleep later).
    func tick() {
        guard isRunning, let endDate else { return }
        tickVersion += 1
        // `>=` plus advancing only once means a tick long after the end (e.g. after the
        // Mac slept for hours) moves exactly one phase forward, never several.
        if now() >= endDate {
            advance(countFocus: true)
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

    /// Moves to the next phase. With autoStartNext off (the default), the next phase is
    /// prepared with its full length and waits for Start.
    private func advance(countFocus: Bool) {
        ticker.stop()
        endDate = nil
        isRunning = false
        isPaused = false

        switch phase {
        case .focus:
            if countFocus { completedFocusCount += 1 }
            let earnedLongBreak = countFocus
                && completedFocusCount % settings.sessionsBeforeLongBreak == 0
            phase = earnedLongBreak ? .longBreak : .shortBreak
        case .longBreak:
            completedFocusCount = 0
            phase = .focus
        case .shortBreak, .idle:
            phase = .focus
        }

        // Read the length now, so a duration changed mid-phase applies from the next phase.
        remainingSeconds = settings.duration(for: phase)
        if settings.autoStartNext {
            run()
        }
    }
}
