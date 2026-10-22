//
//  CapybaraAnimatorTests.swift
//  CapyDoroTests
//
//  B3/B4: the frame animator, the bundled sprite frames, and the controller that picks
//  the pose for each timer state and animates only while the countdown runs.
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

    @Test("Every menu bar pose has art: stand 1, nap 4, hot spring 16, sleep 1")
    func restingPoses() {
        #expect(ArtCatalog.frames(for: .stand).count == 1)
        #expect(ArtCatalog.frames(for: .nap).count == 4)
        #expect(ArtCatalog.frames(for: .spring).count == 16)
        #expect(ArtCatalog.frames(for: .sleep).count == 1)
    }

    @Test("In the menu bar, walking plays the whole walk ×3 + hop loop")
    func menuBarPoseFrames() {
        let frames = ArtCatalog.menuBarPoseFrames()
        #expect(frames[.walk]?.count == 8 * 3 + 9)
        #expect(frames[.jump] == nil)
    }

    @Test("Sprites are full colour, not tinted like the static icon")
    func colourFrames() {
        #expect(ArtCatalog.frames(for: .walk).allSatisfy { !$0.isTemplate })
    }
}

@Suite("Pose animation controller (B3/B4)")
struct PoseAnimationControllerTests {
    let h = EngineHarness { $0.sessionsBeforeLongBreak = 2 }
    let animatorTicker = FakeTicker()
    static let frameCounts: [Pose: Int] = [.stand: 1, .walk: 33, .nap: 4, .spring: 16, .sleep: 1]

    func makeController(motionAllowed: Bool = true) -> (PoseAnimationController, CapybaraAnimator) {
        let animator = CapybaraAnimator(ticker: animatorTicker, isMotionAllowed: { motionAllowed })
        let controller = PoseAnimationController(engine: h.engine, animator: animator,
                                                 frameCounts: Self.frameCounts)
        return (controller, animator)
    }

    /// The controller reacts on the next main-actor turn; let it run.
    func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    @Test("Idle: standing still, no animation timer")
    func idle() async {
        let (controller, _) = makeController()
        await settle()
        #expect(controller.pose == .stand)
        #expect(!animatorTicker.isActive)
    }

    @Test("Running focus: walking at 8 fps")
    func walksDuringFocus() async {
        let (controller, _) = makeController()
        h.engine.start()
        await settle()
        #expect(controller.pose == .walk)
        #expect(animatorTicker.isActive)
        #expect(animatorTicker.interval == 1.0 / 8)
    }

    @Test("Paused: sleeping, still; resuming walks again")
    func pauseSleeps() async {
        let (controller, _) = makeController()
        h.engine.start()
        await settle()
        h.engine.pause()
        await settle()
        #expect(controller.pose == .sleep)
        #expect(!animatorTicker.isActive)
        h.engine.resume()
        await settle()
        #expect(controller.pose == .walk)
        #expect(animatorTicker.isActive)
    }

    @Test("Short break: napping, still while waiting, z's floating at 3 fps once started")
    func shortBreakSits() async {
        let (controller, _) = makeController()
        h.finishCurrentPhase()          // focus ends → short break waits for Start
        await settle()
        #expect(controller.pose == .nap)
        #expect(!animatorTicker.isActive)
        h.engine.start()
        await settle()
        #expect(controller.pose == .nap)
        #expect(animatorTicker.isActive)
        #expect(animatorTicker.interval == 1.0 / 3)
    }

    @Test("Long break: floating in the hot spring at 4 fps")
    func longBreakSprings() async {
        let (controller, _) = makeController()
        h.finishCurrentPhase(); h.finishCurrentPhase(); h.finishCurrentPhase()   // 2nd focus → long break
        h.engine.start()
        await settle()
        #expect(controller.pose == .spring)
        #expect(animatorTicker.isActive)
        #expect(animatorTicker.interval == 1.0 / 4)
    }

    @Test("Focus waiting for Start (after a break): standing still")
    func waitingFocusStands() async {
        let (controller, _) = makeController()
        h.finishCurrentPhase(); h.finishCurrentPhase()   // focus, then break → focus waits
        await settle()
        #expect(controller.pose == .stand)
        #expect(!animatorTicker.isActive)
    }

    @Test("Reduce Motion / animations off: right pose, but a still frame and no timer")
    func noMotion() async {
        let (controller, animator) = makeController(motionAllowed: false)
        h.engine.start()
        await settle()
        #expect(controller.pose == .walk)
        #expect(!animatorTicker.isActive)
        #expect(animator.frameIndex == 0)
    }
}
