//
//  SoundService.swift
//  CapyDoro
//
//  Plays the bundled chime (Resources/chime.m4a). Falls back to the system "Glass"
//  sound if the file is ever missing from the app.
//

import AppKit

final class SoundService: SoundPlaying {
    // Loaded once, the first time it's needed (`lazy`).
    private lazy var chime: NSSound? = {
        guard let url = Bundle.main.url(forResource: "chime", withExtension: "m4a") else {
            return NSSound(named: "Glass")
        }
        return NSSound(contentsOf: url, byReference: true) ?? NSSound(named: "Glass")
    }()

    func playChime() {
        guard let chime else { return }
        chime.stop()   // restart from the beginning if it's still playing
        chime.play()
    }
}
