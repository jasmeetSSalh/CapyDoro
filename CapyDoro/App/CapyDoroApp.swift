//
//  CapyDoroApp.swift
//  CapyDoro
//
//  Entry point. The app has no windows of its own (yet); it lives only in the menu bar.
//

import SwiftUI

@main
struct CapyDoroApp: App {
    var body: some Scene {
        // MenuBarExtra puts an item in the menu bar. The first closure is the dropdown,
        // `label:` is what sits in the bar itself.
        MenuBarExtra {
            MenuContent()
        } label: {
            MenuBarLabel(remainingSeconds: 25 * 60)
        }
        .menuBarExtraStyle(.menu)   // a plain native dropdown menu
    }
}
