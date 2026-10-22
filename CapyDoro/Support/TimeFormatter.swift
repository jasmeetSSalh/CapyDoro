//
//  TimeFormatter.swift
//  CapyDoro
//
//  Turns a number of seconds into "MM:SS" for the menu bar.
//

import Foundation

enum TimeFormatter {
    /// 1500 → "25:00", 599 → "09:59". Minutes are always at least two digits so the
    /// width stays the same; negative values show "00:00".
    static func string(fromSeconds seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }
}
