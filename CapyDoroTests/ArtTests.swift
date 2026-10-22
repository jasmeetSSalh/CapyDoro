//
//  ArtTests.swift
//  CapyDoroTests
//
//  B2+: pose selection, frame ordering, the bundled menu bar icon and its SF Symbol fallback.
//  (Animator tests wait in BacklogTests/ until B3.)
//

import AppKit
import Testing
@testable import CapyDoro

@Suite("Pose (B4)")
struct PoseTests {

    @Test("Each state maps to the right capybara pose")
    func mapping() {
        #expect(Pose.for(phase: .idle, isRunning: false, isPaused: false) == .stand)
        #expect(Pose.for(phase: .focus, isRunning: true, isPaused: false) == .walk)
        #expect(Pose.for(phase: .focus, isRunning: false, isPaused: false) == .stand)   // waiting for Start
        #expect(Pose.for(phase: .shortBreak, isRunning: true, isPaused: false) == .sit)
        #expect(Pose.for(phase: .shortBreak, isRunning: false, isPaused: false) == .sit)
        #expect(Pose.for(phase: .longBreak, isRunning: true, isPaused: false) == .spring)
    }

    @Test("Any paused phase shows the sleeping pose", arguments: [Phase.focus, .shortBreak, .longBreak])
    func pausedSleeps(phase: Phase) {
        #expect(Pose.for(phase: phase, isRunning: false, isPaused: true) == .sleep)
    }

    @Test("Walking runs at ~8 fps, the hop at 10 fps, resting poses loop slowly")
    func frameRates() {
        #expect(Pose.walk.framesPerSecond == 8)
        #expect(Pose.jump.framesPerSecond == 10)
        for pose in [Pose.stand, .sit, .spring, .sleep] {
            #expect((3...4).contains(pose.framesPerSecond))
        }
    }

    @Test("Folder names match the Art/sprites layout")
    func folderNames() {
        #expect(Pose.allCases.map(\.rawValue).sorted() == ["jump", "sit", "sleep", "spring", "stand", "walk"])
    }
}

@Suite("ArtCatalog (B2/B3)")
struct ArtCatalogTests {

    @Test("Frames are picked by pose prefix and sorted by number, not alphabetically")
    func frameOrdering() {
        let files = ["walk_10.png", "walk_2.png", "walk_1.png", "sit_01.png", ".DS_Store", "walk_03@2x.png", "walk_03.png"]
        #expect(ArtCatalog.frameNames(for: .walk, in: files) == ["walk_1", "walk_2", "walk_03", "walk_10"])
    }

    @Test("No matching files means no frames (caller falls back to the static icon)")
    func noFrames() {
        #expect(ArtCatalog.frameNames(for: .spring, in: ["walk_01.png"]).isEmpty)
    }

    @Test("A missing image returns nil instead of crashing")
    func missingImage() {
        #expect(ArtCatalog.image(named: "definitely-not-an-asset") == nil)
    }

    @Test("The capybara menu bar icon ships in the app as an 18 pt template image")
    func bundledMenuBarIcon() {
        #expect(ArtCatalog.image(named: ArtCatalog.menuBarIconName) != nil)
        let icon = ArtCatalog.menuBarIcon(named: ArtCatalog.menuBarIconName)
        #expect(icon.isTemplate)
        #expect(icon.size.height == 18)
    }

    @Test("A missing menu bar icon falls back to a template SF Symbol")
    func menuBarFallback() {
        let icon = ArtCatalog.menuBarIcon(named: "definitely-not-an-asset")
        #expect(icon.isTemplate)
        #expect(ArtCatalog.fallbackSymbolName == "timer")
    }
}
