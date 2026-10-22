//
//  CapybaraAnimatorTests.swift
//  CapyDoroTests
//
//  B3: the frame animator, the bundled walk/hop frames, and the controller that walks the
//  capybara only while focus is running.
//

import AppKit
import Testing
@testable import CapyDoro

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

@Suite("Sprite frames (B3)")
struct SpriteFrameTests {

    @Test("All 8 walk and 9 hop frames ship in the app")
    func bundledFrames() {
        #expect(ArtCatalog.frames(for: .walk).count == 8)
        #expect(ArtCatalog.frames(for: .jump).count == 9)
    }

    @Test("The focus loop is three walks, then one hop")
    func focusLoop() {
        #expect(ArtCatalog.focusLoopFrames().count == 8 * 3 + 9)
    }

    @Test("A pose with no art has no frames (the static icon is used instead)")
    func missingPose() {
        #expect(ArtCatalog.frames(for: .spring).isEmpty)
    }

    @Test("Sprites are full colour, not tinted like the static icon")
    func colourFrames() {
        #expect(ArtCatalog.frames(for: .walk).allSatisfy { !$0.isTemplate })
    }
}

@Suite("Focus animation controller (B3)")
struct FocusAnimationControllerTests {
    let h = EngineHarness()
    let animatorTicker = FakeTicker()

    func makeController(motionAllowed: Bool = true) -> (FocusAnimationController, CapybaraAnimator) {
        let animator = CapybaraAnimator(ticker: animatorTicker, isMotionAllowed: { motionAllowed })
        let controller = FocusAnimationController(engine: h.engine, animator: animator, frameCount: 33)
        return (controller, animator)
    }

    /// The controller reacts on the next main-actor turn; let it run.
    func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    @Test("Idle: no animation timer")
    func idle() async {
        let (controller, _) = makeController()
        await settle()
        #expect(!animatorTicker.isActive)
        _ = controller
    }

    @Test("Starting focus starts the walk at 8 fps")
    func walksDuringFocus() async {
        let (controller, _) = makeController()
        h.engine.start()
        await settle()
        #expect(animatorTicker.isActive)
        #expect(animatorTicker.interval == 1.0 / 8)
        _ = controller
    }

    @Test("Pausing stops the walk; resuming restarts it")
    func pauseStops() async {
        let (controller, _) = makeController()
        h.engine.start()
        await settle()
        h.engine.pause()
        await settle()
        #expect(!animatorTicker.isActive)
        h.engine.resume()
        await settle()
        #expect(animatorTicker.isActive)
        _ = controller
    }

    @Test("A break stops the walk")
    func breakStops() async {
        let (controller, _) = makeController()
        h.engine.start()
        await settle()
        h.engine.skip()
        await settle()
        #expect(!animatorTicker.isActive)
        _ = controller
    }

    @Test("Reduce Motion / animations off: focus shows a still frame, no timer")
    func noMotion() async {
        let (controller, animator) = makeController(motionAllowed: false)
        h.engine.start()
        await settle()
        #expect(!animatorTicker.isActive)
        #expect(animator.frameIndex == 0)
        _ = controller
    }

    @Test("The walk runs only while focus is running")
    func isWalking() async {
        let (controller, _) = makeController()
        #expect(!controller.isWalking)
        h.engine.start()
        await settle()
        #expect(controller.isWalking)
        h.engine.pause()
        await settle()
        #expect(!controller.isWalking)
    }
}

