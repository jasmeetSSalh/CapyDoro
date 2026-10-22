//
//  PomodoroEngine.swift
//  CapyDoro
//
//  The timer's brain: which phase we're in, when it ends, and what comes next.
//  SKELETON: the shape is final, the behaviour arrives in M2 (countdown) and M3 (cycle).
//

import Foundation
import Observation

@Observable
final class PomodoroEngine {
    private(set) var phase: Phase = .idle
    private(set) var isRunning = false
    private(set) var isPaused = false
    private(set) var endDate: Date?
    private(set) var remainingSeconds = 0
    private(set) var completedFocusCount = 0

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

    var displayRemaining: Int {
        settings.duration(for: .focus)   // M2: compute from endDate
    }

    func start() {}               // M2
    func pause() {}               // M2
    func resume() {}              // M2
    func reset() {}               // M2
    func skip() {}                // M3
    func tick() {}                // M2/M3
    func restoreSavedState() {}   // M6
}
