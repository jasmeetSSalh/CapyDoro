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
    @State private var poseAnimation: PoseAnimationController
    private let poseFrames: [Pose: [NSImage]]
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

        // The capybara poses. Motion is checked each time an animated pose starts.
        let poseFrames = ArtCatalog.menuBarPoseFrames()
        let animator = CapybaraAnimator(ticker: RepeatingTicker()) {
            settings.animationsEnabled && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
        // Created after restoring, so a restored session shows the right pose right away.
        let poseAnimation = PoseAnimationController(engine: engine, animator: animator,
                                                    frameCounts: poseFrames.mapValues(\.count))

        self.poseFrames = poseFrames
        _settings = State(initialValue: settings)
        _engine = State(initialValue: engine)
        _animator = State(initialValue: animator)
        _poseAnimation = State(initialValue: poseAnimation)
    }

    var body: some Scene {
        // MenuBarExtra puts an item in the menu bar. The first closure is the dropdown,
        // `label:` is what sits in the bar itself.
        MenuBarExtra {
            MenuContent(engine: engine, settings: settings)
        } label: {
            MenuBarLabel(engine: engine, poseAnimation: poseAnimation,
                         animator: animator, poseFrames: poseFrames)
        }
        .menuBarExtraStyle(.menu)   // a plain native dropdown menu

        // The standard macOS Settings window, opened from the dropdown.
        Settings {
            SettingsView(settings: settings, launchAtLogin: launchAtLogin)
        }
    }
}
