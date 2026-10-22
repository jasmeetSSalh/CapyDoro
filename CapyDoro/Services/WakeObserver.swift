//
//  WakeObserver.swift
//  CapyDoro
//
//  Calls `onWake` right after the Mac wakes from sleep, so the menu bar shows the
//  correct time immediately instead of waiting for the next timer tick.
//  Created once at launch and kept for the app's whole life.
//

import AppKit

final class WakeObserver {
    private var token: NSObjectProtocol?

    init(onWake: @escaping () -> Void) {
        token = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            // `queue: .main` delivers on the main thread; this tells Swift so.
            MainActor.assumeIsolated { onWake() }
        }
    }
}
