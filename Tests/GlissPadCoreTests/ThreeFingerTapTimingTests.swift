@testable import GlissPadCore
import Foundation
import XCTest

final class ThreeFingerTapTimingTests: XCTestCase {
    func testTapTriggersWhenReleaseStartsOneFingerAtATime() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)

        let gestures = recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.08))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTap])
    }

    func testTapTriggersWhenReleaseArrivesBeforeStableTimerFires() {
        let recognizer = recognizer(stableMilliseconds: 30)

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)

        let gestures = recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.04))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTap])
    }

    func testTapSurvivesTouchIdentifierChangesAndClickNoise() {
        let recognizer = recognizer()
        let changedTouches = [
            touch(id: 10, x: 0.361, pressure: 0.8),
            touch(id: 11, x: 0.401, pressure: 0.8),
            touch(id: 12, x: 0.441, pressure: 0.8)
        ]

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: changedTouches, time: 1.03, clickGeneration: 1)).isEmpty)

        let gestures = recognizer.process(frame(touches: Array(changedTouches.prefix(2)), time: 1.08))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTap])
    }

    func testTapCancelsOnRealPressPressure() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(pressure: 1.0), time: 1.03)).isEmpty)

        XCTAssertTrue(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.08)).isEmpty)
    }

    private func recognizer(stableMilliseconds: Int = 0) -> GestureRecognizer {
        var rule = ThreeFingerGestureRule(
            name: "Three Finger Tap",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(name: "HUD"))]
        )
        rule.common = ThreeFingerCommonOptions(minStableFingerCountDurationMilliseconds: stableMilliseconds)
        rule.tap = ThreeFingerTapOptions(tapCount: 1, maximumTapMilliseconds: 180, maximumMovement: 0.05)
        let trigger = GestureRule.threeFinger(id: "three-tap", type: .threeFingerTap, rule: rule)
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

    private func touches(pressure: Double = 0.2) -> [TouchPoint] {
        [
            touch(id: 1, x: 0.36, pressure: pressure),
            touch(id: 2, x: 0.40, pressure: pressure),
            touch(id: 3, x: 0.44, pressure: pressure)
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
