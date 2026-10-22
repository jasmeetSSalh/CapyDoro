//
//  CapyDoroApp.swift
//  CapyDoro
//
//  Entry point. Builds the engine and its services once, then hands them to the views.
//  The app has no windows of its own; it lives only in the menu bar.
//

import SwiftUI

@main
struct CapyDoroApp: App {
    // @State keeps these objects alive for the app's whole life (created once, not per redraw).
    @State private var settings: SettingsStore
    @State private var engine: PomodoroEngine

    init() {
        let settings = SettingsStore()
        _settings = State(initialValue: settings)
        _engine = State(initialValue: PomodoroEngine(
            settings: settings,
            notifications: NotificationService(),
            sound: SoundService(),
            ticker: RepeatingTicker()
        ))
    }

    var body: some Scene {
        // MenuBarExtra puts an item in the menu bar. The first closure is the dropdown,
        // `label:` is what sits in the bar itself.
        MenuBarExtra {
            MenuContent(engine: engine, settings: settings)
        } label: {
            MenuBarLabel(engine: engine)
        }
        .menuBarExtraStyle(.menu)   // a plain native dropdown menu
    }
}
