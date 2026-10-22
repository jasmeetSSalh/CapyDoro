//
//  ArtCatalog.swift
//  CapyDoro
//
//  Loads capybara art from Assets.xcassets, falling back to an SF Symbol when something
//  is missing, so the app always has an icon even if an asset gets deleted.
//

import AppKit
import os

enum ArtCatalog {
    /// The capybara silhouette in Assets.xcassets (made by Art/tools/make_icon.py).
    static let menuBarIconName = "MenuBarIcon"
    static let fallbackSymbolName = "timer"

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CapyDoro",
                                       category: "art")

    /// An image from the asset catalog, or nil if there isn't one with that name.
    static func image(named name: String) -> NSImage? {
        NSImage(named: name)
    }

    /// The menu bar icon as a template image (macOS recolours it for light/dark menu bars).
    /// Falls back to the SF Symbol `timer` and logs which asset is missing.
    static func menuBarIcon(named name: String = menuBarIconName) -> NSImage {
        let icon: NSImage
        if let art = image(named: name) {
            icon = art
        } else {
            logger.warning("Menu bar art '\(name)' is missing; using SF Symbol '\(fallbackSymbolName)'")
            icon = NSImage(systemSymbolName: fallbackSymbolName, accessibilityDescription: "Timer")
                ?? NSImage()
        }
        icon.isTemplate = true
        return icon
    }

    /// Sprite frame names for a pose, in play order: "walk_2" comes before "walk_10".
    /// `@2x` files are skipped because macOS pairs them with their 1x file automatically.
    static func frameNames(for pose: Pose, in fileNames: [String]) -> [String] {
        let prefix = pose.rawValue + "_"
        let frames = fileNames
            .filter { $0.hasPrefix(prefix) && $0.hasSuffix(".png") && !$0.contains("@2x") }
            .map { String($0.dropLast(".png".count)) }
        // Sort by the number after the underscore, not alphabetically.
        return frames.sorted { frameNumber($0, prefix) < frameNumber($1, prefix) }
    }

    private static func frameNumber(_ name: String, _ prefix: String) -> Int {
        Int(name.dropFirst(prefix.count)) ?? 0
    }
}
