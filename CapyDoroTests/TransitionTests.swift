//
//  TransitionTests.swift
//  CapyDoroTests
//
//  B5: which phase changes get a transition, playing it once, and handing over to the
//  new pose afterwards. Pause, resume, reset and launch switch instantly.
//

import Testing
@testable import CapyDoro

@Suite("Transition table (B5)")
struct TransitionTableTests {

    @Test("Phase changes map to the right transition")
    func mapping() {
        #expect(Transition.between(.walk, .nap) == .flop)
        #expect(Transition.between(.walk, .spring) == .dive)
        #expect(Transition.between(.nap, .stand) == .wake)
        #expect(Transition.between(.nap, .walk) == .wake)        // autoStartNext on
        #expect(Transition.between(.spring, .stand) == .emerge)
        #expect(Transition.between(.spring, .walk) == .emerge)
    }

    @Test("Pause, resume and starting from idle switch instantly")
    func instant() {
        #expect(Transition.between(.walk, .sleep) == nil)
        #expect(Transition.between(.sleep, .walk) == nil)
        #expect(Transition.between(.stand, .walk) == nil)
        #expect(Transition.between(.walk, .stand) == nil)
    }

    @Test("Every transition's frames ship in the app")
    func bundledFrames() {
        #expect(ArtCatalog.frames(for: .flop).count == 8)
        #expect(ArtCatalog.frames(for: .dive).count == 10)
        #expect(ArtCatalog.frames(for: .wake).count == 7)
        #expect(ArtCatalog.frames(for: .emerge).count == 7)
    }
}

@Suite("Play once (B5)")
struct PlayOnceTests {
    let ticker = FakeTicker()

    @Test("Plays each frame once, then calls the completion exactly once and stops")
    func playsOnce() {
        let animator = CapybaraAnimator(ticker: ticker, isMotionAllowed: { true })
        var finished = 0
        #expect(animator.playOnce(frameCount: 4, framesPerSecond: 10) { finished += 1 })
        #expect(ticker.interval == 1.0 / 10)

        for expected in 1...3 {
            ticker.fire()
            #expect(animator.frameIndex == expected)
        }
        #expect(finished == 0)
        ticker.fire()                 // after the last frame
        #expect(finished == 1)
        #expect(!ticker.isActive)
        #expect(animator.frameIndex == 0)
    }

    @Test("With motion off it plays nothing and says so")
    func motionOff() {
        let animator = CapybaraAnimator(ticker: ticker, isMotionAllowed: { false })
        var finished = false
        #expect(!animator.playOnce(frameCount: 4, framesPerSecond: 10) { finished = true })
        #expect(!ticker.isActive)
        #expect(!finished)
    }

    @Test("Stopping mid-way cancels the completion")
    func stopCancels() {
        let animator = CapybaraAnimator(ticker: ticker, isMotionAllowed: { true })
        var finished = false
        animator.playOnce(frameCount: 4, framesPerSecond: 10) { finished = true }
        ticker.fire()
        animator.stop()
        for _ in 1...5 { ticker.fire() }
        #expect(!finished)
    }
}

@Suite("Transitions in the pose controller (B5)")
struct PoseTransitionTests {
    let h = EngineHarness { $0.sessionsBeforeLongBreak = 2 }
    let animatorTicker = FakeTicker()
    static let frameCounts: [Pose: Int] = [.stand: 1, .walk: 33, .nap: 4, .spring: 16, .sleep: 1]
    static let transitionCounts: [Transition: Int] = [.flop: 8, .dive: 10, .wake: 7, .emerge: 7]

    func makeController(motionAllowed: Bool = true) -> PoseAnimationController {
        let animator = CapybaraAnimator(ticker: animatorTicker, isMotionAllowed: { motionAllowed })
        return PoseAnimationController(engine: h.engine, animator: animator,
                                       frameCounts: Self.frameCounts,
                                       transitionFrameCounts: Self.transitionCounts)
    }

    /// The controller reacts on the next main-actor turn; let it run.
    func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    /// Fires the animation timer through a whole transition.
    func playThrough(_ count: Int) {
        for _ in 0..<count { animatorTicker.fire() }
    }

    @Test("Focus → short break: flop at 10 fps, then the nap (still, waiting for Start)")
    func flop() async {
        let controller = makeController()
        h.engine.start()
        await settle()
        h.finishCurrentPhase()
        await settle()
        #expect(controller.transition == .flop)
        #expect(controller.pose == .nap)
        #expect(animatorTicker.interval == 1.0 / 10)

        playThrough(8)
        #expect(controller.transition == nil)
        #expect(!animatorTicker.isActive)       // the break waits, so the nap is still
    }

    @Test("Starting the break during the flop: the nap animates once the flop ends")
    func startDuringTransition() async {
        let controller = makeController()
        h.engine.start()
        await settle()
        h.finishCurrentPhase()
        await settle()
        h.engine.start()                         // start the break mid-flop
        await settle()
        #expect(controller.transition == .flop)  // keeps playing

        playThrough(8)
        #expect(controller.transition == nil)
        #expect(animatorTicker.isActive)
        #expect(animatorTicker.interval == 1.0 / 3)
    }

    @Test("Focus → long break: dive")
    func dive() async {
        let controller = makeController()
        h.finishCurrentPhase(); h.finishCurrentPhase()   // 1st focus + short break
        h.engine.start()
        await settle()
        h.finishCurrentPhase()                           // 2nd focus → long break
        await settle()
        #expect(controller.transition == .dive)
        #expect(controller.pose == .spring)
    }

    @Test("Short break → focus: wake; long break → focus: emerge")
    func wakeAndEmerge() async {
        let controller = makeController()
        h.finishCurrentPhase()                   // → short break
        await settle()
        playThrough(8)
        h.finishCurrentPhase()                   // short break → focus (waiting)
        await settle()
        #expect(controller.transition == .wake)
        #expect(controller.pose == .stand)
        playThrough(7)

        h.engine.start()
        await settle()
        h.finishCurrentPhase()                   // 2nd focus → long break
        await settle()
        playThrough(10)
        h.finishCurrentPhase()                   // long break → focus
        await settle()
        #expect(controller.transition == .emerge)
    }

    @Test("Pause and resume switch instantly")
    func pauseIsInstant() async {
        let controller = makeController()
        h.engine.start()
        await settle()
        h.engine.pause()
        await settle()
        #expect(controller.transition == nil)
        #expect(controller.pose == .sleep)
        h.engine.resume()
        await settle()
        #expect(controller.transition == nil)
        #expect(controller.pose == .walk)
    }

    @Test("Reset during a break switches instantly to standing")
    func resetIsInstant() async {
        let controller = makeController()
        h.finishCurrentPhase()
        await settle()
        playThrough(8)
        h.engine.reset()
        await settle()
        #expect(controller.transition == nil)
        #expect(controller.pose == .stand)
    }

    @Test("Reduce Motion / animations off: no transition, straight to the new pose")
    func noMotion() async {
        let controller = makeController(motionAllowed: false)
        h.engine.start()
        await settle()
        h.finishCurrentPhase()
        await settle()
        #expect(controller.transition == nil)
        #expect(controller.pose == .nap)
    }

    @Test("Launching into a break shows the break pose without a transition")
    func noTransitionAtLaunch() async {
        h.finishCurrentPhase()                   // the engine is already in a short break
        let controller = makeController()
        await settle()
        #expect(controller.transition == nil)
        #expect(controller.pose == .nap)
    }
}
