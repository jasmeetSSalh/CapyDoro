//
//  MenuBarLabel.swift
//  CapyDoro
//
//  What you see in the menu bar: an icon and the time left, e.g. "25:00".
//

import SwiftUI

struct MenuBarLabel: View {
    let remainingSeconds: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text(TimeFormatter.string(fromSeconds: remainingSeconds))
                .monospacedDigit()   // every digit gets the same width, so the item never jiggles
        }
    }
}
