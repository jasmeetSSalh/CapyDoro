//
//  MenuContent.swift
//  CapyDoro
//
//  The dropdown shown when you click the menu bar item.
//

import SwiftUI

struct MenuContent: View {
    var body: some View {
        // A disabled Button shows as greyed-out, unclickable text: a status line.
        Button("Ready to focus") {}
            .disabled(true)

        Divider()

        Button("Start") {}
            .disabled(true)   // wired up in M2

        Divider()

        // An agent app has no Dock icon and no app menu, so this is the only way to quit.
        Button("Quit CapyDoro") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
