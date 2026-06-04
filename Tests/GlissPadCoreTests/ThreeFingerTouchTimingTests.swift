@testable import GlissPadCore
import Foundation
import XCTest

final class ThreeFingerTouchTimingTests: XCTestCase {
    func testTouchStartThresholdReachedTriggersWhenStable() {
        let recognizer = recognizer(event: .touchStart, timing: .thresholdReached)

        XCTAssertEqual(recognizer.process(frame(touches: touches(), time: 1.0)).map(\.kind), [.threeFingerTouch])
    }

    func testTouchStartContinuousRepeatsWhileTouching() {
        let recognizer = recognizer(event: .touchStart, timing: .continuous)

        XCTAssertEqual(recognizer.process(frame(touches: touches(), time: 1.0)).map(\.kind), [.threeFingerTouch])
        XCTAssertEqual(recognizer.processTimer(at: 1.3).map(\.kind), [.threeFingerTouch])
    }

    func testTouchStartReleaseTriggersAfterAllFingersLift() {
        let recognizer = recognizer(event: .touchStart, timing: .release)

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.1)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], time: 1.12)).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchThresholdReachedTriggersAfterHold() {
        let recognizer = recognizer(event: .longTouch, timing: .thresholdReached)

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertEqual(recognizer.processTimer(at: 1.1).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchContinuousRepeatsAfterHold() {
        let recognizer = recognizer(event: .longTouch, timing: .continuous)

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertEqual(recognizer.processTimer(at: 1.1).map(\.kind), [.threeFingerTouch])
        XCTAssertEqual(recognizer.processTimer(at: 1.4).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchReleaseTriggersWhenReleaseStartsAfterHold() {
        let recognizer = recognizer(event: .longTouch, timing: .release)

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.12)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.14)).map(\.kind), [.threeFingerTouch])
    }

    func testTouchEndThresholdReachedTriggersWhenReleaseStarts() {
        let recognizer = recognizer(event: .touchEnd, timing: .thresholdReached)

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.1)).map(\.kind), [.threeFingerTouch])
    }

    func testTouchEndContinuousTriggersWhenReleaseStarts() {
        let recognizer = recognizer(event: .touchEnd, timing: .continuous)

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.1)).map(\.kind), [.threeFingerTouch])
    }

    func testTouchEndReleaseTriggersAfterAllFingersLift() {
        let recognizer = recognizer(event: .touchEnd, timing: .release)

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.1)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], time: 1.12)).map(\.kind), [.threeFingerTouch])
    }

    func testTouchEndSurvivesClickNoiseAndTouchIdentifierChanges() {
        let recognizer = recognizer(event: .touchEnd, timing: .thresholdReached)
        let changedTouches = [
            touch(id: 10, x: 0.39, pressure: 0.8),
            touch(id: 11, x: 0.43, pressure: 0.8),
            touch(id: 12, x: 0.47, pressure: 0.8)
        ]

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: changedTouches, time: 1.04, clickGeneration: 1)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: Array(changedTouches.prefix(2)), time: 1.08)).map(\.kind), [.threeFingerTouch])
    }

    func testTouchEndDoesNotLoseReleaseBeforeStableTimerFires() {
        let recognizer = recognizer(
            event: .touchEnd,
            timing: .thresholdReached,
            stableMilliseconds: 30
        )

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.08)).map(\.kind), [.threeFingerTouch])
    }

    private func recognizer(
        event: ThreeFingerTouchEvent,
        timing: ThreeFingerTriggerTiming,
        stableMilliseconds: Int = 0
    ) -> GestureRecognizer {
        var rule = ThreeFingerGestureRule(
            name: "Three Finger Touch",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(name: "HUD"))]
        )
        rule.common = ThreeFingerCommonOptions(minStableFingerCountDurationMilliseconds: stableMilliseconds)
        rule.touch = ThreeFingerTouchOptions(
            event: event,
            holdMilliseconds: 100,
            movementTolerance: 0.08,
            repeatIntervalMilliseconds: 300,
            triggerTiming: timing
        )
        let trigger = GestureRule.threeFinger(id: "three-touch", type: .threeFingerTouch, rule: rule)
        return GestureRecognizer(configuration: GestureConfiguration(triggers: [trigger]))
    }

    private func frame(
        touches: [TouchPoint],
        time: TimeInterval,
        clickGeneration: UInt64 = 0
    ) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: time,
            frameNumber: Int(time * 100),
            clickGeneration: clickGeneration
        )
    }

    private func touches() -> [TouchPoint] {
        [
            touch(id: 1, x: 0.36),
            touch(id: 2, x: 0.40),
            touch(id: 3, x: 0.44)
        ]
    }

    private func touch(id: Int, x: Double, pressure: Double = 0.2) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: 0.5),
            pressure: pressure,
            size: 0.2
        )
    }
}
