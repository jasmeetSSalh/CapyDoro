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
//  Every change is saved, so quitting, a crash or restarting the Mac loses nothing.
//  Reset clears the saved session. (Full rules: plan.md, section 4 "Restore on launch".)
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
        notifications.requestAuthorizationIfNeeded()
        run()
    }

    func pause() {
        guard isRunning else { return }
        remainingSeconds = displayRemaining
        endDate = nil
        isRunning = false
        isPaused = true
        ticker.stop()
        notifications.cancelPending()   // no "ghost" alert for a paused session
        save()
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
        notifications.cancelPending()
        save()
    }

    /// Ends the current phase now, without counting a skipped focus.
    func skip() {
        guard phase != .idle else { return }
        advance(countFocus: false)
    }

    /// Called once at launch. Picks up the timer from the last save:
    /// - still running → keeps counting to the same end time
    /// - ended while the app was closed → moves on one phase and waits for Start
    ///   (no chime: macOS already showed the alert at the right time)
    /// - paused or waiting → restored as it was
    /// The completed-focus count is restored in every case.
    func restoreSavedState() {
        let saved = settings.savedTimer
        phase = saved.phase
        completedFocusCount = saved.completedFocusCount
        guard phase != .idle else { return }

        if let end = saved.endDate {
            if end > now() {
                startCountdown(until: end)
            } else {
                advance(countFocus: true, allowAutoStart: false)
            }
        } else if let paused = saved.pausedRemainingSeconds {
            remainingSeconds = paused
            isPaused = true
        } else {
            remainingSeconds = settings.duration(for: phase)
        }
    }

    #if DEBUG
    /// Testing aid (debug builds only): makes the running phase end in a few seconds.
    func debugJumpToEnd(secondsLeft: Int = 5) {
        guard isRunning else { return }
        startCountdown(until: now().addingTimeInterval(TimeInterval(secondsLeft)))
    }
    #endif

    /// Called every second while running, and right after the Mac wakes from sleep.
    func tick() {
        guard isRunning, let endDate else { return }
        tickVersion += 1
        // `>=` plus advancing only once means a tick long after the end (e.g. after the
        // Mac slept for hours) moves exactly one phase forward, never several.
        if now() >= endDate {
            if settings.soundEnabled { sound.playChime() }
            advance(countFocus: true)
        }
    }

    // MARK: - Private

    /// Starts counting down `remainingSeconds` from now.
    private func run() {
        startCountdown(until: now().addingTimeInterval(TimeInterval(remainingSeconds)))
    }

    private func startCountdown(until end: Date) {
        endDate = end
        isRunning = true
        // Scheduled with macOS up front, so the alert appears on time even if this app
        // is slowed down in the background.
        notifications.scheduleEndOfPhase(phase, at: end)
        // `[weak self]` stops the timer from keeping the engine alive forever.
        ticker.start(interval: 1) { [weak self] in
            self?.tick()
        }
        save()
    }

    /// Moves to the next phase. With autoStartNext off (the default), the next phase is
    /// prepared with its full length and waits for Start.
    private func advance(countFocus: Bool, allowAutoStart: Bool = true) {
        ticker.stop()
        notifications.cancelPending()   // matters for Skip; harmless after a natural end
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
        if allowAutoStart && settings.autoStartNext {
            run()
        } else {
            save()
        }
    }

    private func save() {
        settings.savedTimer = SettingsStore.SavedTimer(
            phase: phase,
            endDate: endDate,
            pausedRemainingSeconds: isPaused ? remainingSeconds : nil,
            completedFocusCount: completedFocusCount
        )
    }
}
