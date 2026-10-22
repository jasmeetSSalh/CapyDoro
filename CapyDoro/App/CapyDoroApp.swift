//
//  CapyDoroApp.swift
//  CapyDoro
//
//  Entry point. Builds the engine and its services once, then hands them to the views.
//  The app has no windows of its own; it lives only in the menu bar.
//

import AppKit
import SwiftUI

@main
struct CapyDoroApp: App {
    // @State keeps these objects alive for the app's whole life (created once, not per redraw).
    @State private var settings: SettingsStore
    @State private var engine: PomodoroEngine
    @State private var animator: CapybaraAnimator
    @State private var focusAnimation: FocusAnimationController
    private let focusFrames: [NSImage]
    private let launchAtLogin = LaunchAtLoginService()
    private let wakeObserver: WakeObserver

    init() {
        let settings = SettingsStore()
        let engine = PomodoroEngine(
            settings: settings,
            notifications: NotificationService(),
            sound: SoundService(),
            ticker: RepeatingTicker()
        )
        engine.restoreSavedState()   // continue a session from before quitting
        wakeObserver = WakeObserver { engine.tick() }

        // The walking capybara. Motion is checked each time a focus starts or resumes.
        let focusFrames = ArtCatalog.focusLoopFrames()
        let animator = CapybaraAnimator(ticker: RepeatingTicker()) {
            settings.animationsEnabled && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
        // Created after restoring, so a session that's still running starts walking right away.
        let focusAnimation = FocusAnimationController(engine: engine, animator: animator,
                                                      frameCount: focusFrames.count)

        self.focusFrames = focusFrames
        _settings = State(initialValue: settings)
        _engine = State(initialValue: engine)
        _animator = State(initialValue: animator)
        _focusAnimation = State(initialValue: focusAnimation)
    }

    var body: some Scene {
        // MenuBarExtra puts an item in the menu bar. The first closure is the dropdown,
        // `label:` is what sits in the bar itself.
        MenuBarExtra {
            MenuContent(engine: engine, settings: settings)
        } label: {
            MenuBarLabel(engine: engine, focusAnimation: focusAnimation,
                         animator: animator, focusFrames: focusFrames)
        }
        .menuBarExtraStyle(.menu)   // a plain native dropdown menu

        // The standard macOS Settings window, opened from the dropdown.
        Settings {
            SettingsView(settings: settings, launchAtLogin: launchAtLogin)
        }
    }
}
