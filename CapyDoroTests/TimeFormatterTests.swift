//
//  TimeFormatterTests.swift
//  CapyDoroTests
//
//  M1/M2 and M6: the menu bar shows MM:SS, always zero-padded so its width never jumps.
//

import Testing
@testable import CapyDoro

@Suite("TimeFormatter")
struct TimeFormatterTests {

    @Test("Formats seconds as MM:SS", arguments: [
        (1500, "25:00"),
        (599, "09:59"),
        (60, "01:00"),
        (59, "00:59"),
        (5, "00:05"),
        (0, "00:00"),
        (7200, "120:00"),   // longest allowed focus
    ])
    func formats(seconds: Int, expected: String) {
        #expect(TimeFormatter.string(fromSeconds: seconds) == expected)
    }

    @Test("Negative values show 00:00 instead of garbage")
    func negativeShowsZero() {
        #expect(TimeFormatter.string(fromSeconds: -3) == "00:00")
    }

    @Test("10:00 and 09:59 are the same width (no menu bar jiggle)")
    func widthIsStable() {
        #expect(TimeFormatter.string(fromSeconds: 600).count == TimeFormatter.string(fromSeconds: 599).count)
    }
}
