//
//  ArtTests.swift
//  CapyDoroTests (backlog B2–B4)
//
//  NOT in the test target yet. Move this file into CapyDoroTests/ when starting B2.
//  Covers pose selection, frame ordering, the SF Symbol fallback and the animator.
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

    @Test("A missing menu bar icon falls back to a template SF Symbol")
    func menuBarFallback() {
        let icon = ArtCatalog.menuBarIcon(named: "definitely-not-an-asset")
        #expect(icon.isTemplate)
        #expect(ArtCatalog.fallbackSymbolName == "timer")
    }
}

@Suite("CapybaraAnimator (B3)")
struct CapybaraAnimatorTests {
    let ticker = FakeTicker()

    @Test("Playing a multi-frame pose cycles frames at the requested rate")
    func cycles() {
        let animator = CapybaraAnimator(ticker: ticker, isMotionAllowed: { true })
        animator.play(frameCount: 8, framesPerSecond: 8)
        #expect(ticker.isActive)
        #expect(ticker.interval == 1.0 / 8)
        #expect(animator.frameIndex == 0)

        for _ in 1...3 { ticker.fire() }
        #expect(animator.frameIndex == 3)
        for _ in 1...5 { ticker.fire() }
        #expect(animator.frameIndex == 0)   // wrapped around
    }

    @Test("Reduce Motion / animations off shows a static frame and no timer")
    func reduceMotion() {
        let animator = CapybaraAnimator(ticker: ticker, isMotionAllowed: { false })
        animator.play(frameCount: 8, framesPerSecond: 8)
        #expect(!ticker.isActive)
        #expect(animator.frameIndex == 0)
    }

    @Test("A single-frame pose needs no timer")
    func singleFrame() {
        let animator = CapybaraAnimator(ticker: ticker, isMotionAllowed: { true })
        animator.play(frameCount: 1, framesPerSecond: 3)
        #expect(!ticker.isActive)
    }

    @Test("Stop halts the timer and returns to the first frame")
    func stop() {
        let animator = CapybaraAnimator(ticker: ticker, isMotionAllowed: { true })
        animator.play(frameCount: 4, framesPerSecond: 8)
        ticker.fire()
        animator.stop()
        #expect(!ticker.isActive)
        #expect(animator.frameIndex == 0)
    }
}
