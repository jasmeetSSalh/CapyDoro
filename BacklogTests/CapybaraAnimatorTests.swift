//
//  CapybaraAnimatorTests.swift
//  CapyDoroTests (backlog B3)
//
//  NOT in the test target yet. Move this file into CapyDoroTests/ when starting B3.
//

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
