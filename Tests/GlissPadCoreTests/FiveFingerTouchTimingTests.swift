@testable import GlissPadCore
import Foundation
import XCTest

final class FiveFingerTouchTimingTests: XCTestCase {
    func testTouchEndToleratesSlowFiveFingerArrival() {
        let recognizer = recognizer(event: .touchEnd, timing: .thresholdReached)

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 2), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 4), time: 1.16)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.30)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(count: 4), time: 1.40))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTouch])
    }

    func testLongTouchToleratesExtraContactNoise() {
        let recognizer = recognizer(event: .longTouch, timing: .thresholdReached)

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 6), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 6), time: 1.08)).isEmpty)
        let gestures = recognizer.processTimer(at: 1.60)

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTouch])
    }

    func testLongTouchIgnoresPressureNoiseBeforeHoldDeadline() {
        let recognizer = recognizer(event: .longTouch, timing: .thresholdReached)

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5, pressure: 1.1), time: 1.08)).isEmpty)
        let gestures = recognizer.processTimer(at: 1.60)

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTouch])
    }

    func testLongTouchStillCancelsOnRealClickEvent() {
        let recognizer = recognizer(event: .longTouch, timing: .thresholdReached)

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.08)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.12, clickGeneration: 1)).isEmpty)
        XCTAssertTrue(recognizer.processTimer(at: 1.60).isEmpty)
    }

    func testTouchEndToleratesExtraContactNoise() {
        let recognizer = recognizer(event: .touchEnd, timing: .thresholdReached)

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 6), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 6), time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(count: 4), time: 1.20))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTouch])
    }

    func testTouchEndIgnoresPressureAndMovementBeforeRelease() {
        let recognizer = recognizer(event: .touchEnd, timing: .thresholdReached)

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5, pressure: 0.9), time: 1.08)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5, x: 0.64), time: 1.16)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(count: 4, x: 0.64), time: 1.20))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTouch])
    }

    private func recognizer(
        event: FiveFingerTouchEvent,
        timing: ThreeFingerTriggerTiming
    ) -> GestureRecognizer {
        var rule = fiveFingerRule()
        rule.touch = FiveFingerTouchOptions(
            event: event,
            holdMilliseconds: 500,
            stableMilliseconds: 60,
            movementTolerance: 0.09,
            triggerTiming: timing
        )
        let trigger = GestureRule.fiveAndMoreFinger(id: "five-touch", type: .fiveFingerTouch, rule: rule)
        return GestureRecognizer(configuration: GestureConfiguration(triggers: [trigger]))
    }

    private func fiveFingerRule() -> FiveAndMoreFingerGestureRule {
        guard case .fiveAndMoreFinger(_, _, let rule) = GestureTriggerType.fiveFingerTouch
            .defaultTrigger(id: "five-touch", ordinal: 1) else {
            return FiveAndMoreFingerGestureRule(
                name: "Five Finger Touch",
                isEnabled: true,
                cooldownMilliseconds: 650,
                actions: []
            )
        }
        return rule
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

    private func touches(count: Int, x: Double = 0.5, pressure: Double = 0.2) -> [TouchPoint] {
        (0..<count).map { index in
            let offset = Double(index) - Double(count - 1) / 2
            return TouchPoint(
                id: index + 1,
                state: .touching,
                position: NormalizedPoint(x: x + offset * 0.035, y: 0.5),
                pressure: pressure,
                size: 0.2
            )
        }
    }
}
