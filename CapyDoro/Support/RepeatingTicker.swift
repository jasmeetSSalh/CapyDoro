//
//  RepeatingTicker.swift
//  CapyDoro
//
//  The real timer behind the `Ticking` protocol.
//

import Foundation

final class RepeatingTicker: Ticking {
    private var timer: Timer?

    func start(interval: TimeInterval, _ handler: @escaping () -> Void) {
        stop()
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            // Timers added to the main run loop fire on the main thread; this tells Swift so.
            MainActor.assumeIsolated { handler() }
        }
        timer.tolerance = interval * 0.1   // lets macOS batch wake-ups to save battery
        // `.common` mode keeps the timer firing while a menu is open. In the default mode
        // the countdown would freeze whenever you click the menu bar item.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
