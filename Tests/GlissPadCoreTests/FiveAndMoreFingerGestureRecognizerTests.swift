@testable import GlissPadCore
import Foundation
import XCTest

final class FiveAndMoreFingerGestureRecognizerTests: XCTestCase {
    func testTouchStartTriggersWhenFiveFingersArrive() {
        let recognizer = recognizer(.fiveFingerTouch)

        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.05))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTouch])
    }

    func testStableTouchWaitsForConfiguredStableDuration() {
        var rule = fiveAndMoreRule(.fiveFingerTouch)
        rule.touch = FiveFingerTouchOptions(event: .stableTouch, stableMilliseconds: 80)
        let recognizer = recognizer(.fiveFingerTouch, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.09))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTouch])
    }

    func testTapTriggersAfterRelease() {
        let recognizer = recognizer(.fiveFingerTap)

        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.12))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTap])
    }

    func testPressTriggersAfterFiveFingerPressureThreshold() {
        var rule = fiveAndMoreRule(.fiveFingerPress)
        rule.press = FourFingerPressOptions(level: .normal, minimumPressure: 0.5)
        let recognizer = recognizer(.fiveFingerPress, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: fiveTouches(at: 0.4, 0.5, pressure: 0.8), time: 1.08))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerPress])
    }

    func testSwipeTriggersOnFiveFingerDirectionalMovement() {
        var rule = fiveAndMoreRule(.fiveFingerSwipe)
        rule.swipe = ThreeFingerSwipeOptions(direction: .right, minimumTravel: 0.16, minimumVelocity: 0.5)
        let recognizer = recognizer(.fiveFingerSwipe, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.25, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.25, 0.5), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: fiveTouches(at: 0.55, 0.5), time: 1.22))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerSwipe])
    }

    func testScaleTriggersOnThumbFourFingerSpread() {
        var rule = fiveAndMoreRule(.thumbFourFingerScale)
        rule.scale = ThreeFingerScaleOptions(
            direction: .spreadOut,
            minimumScaleDelta: 0.25,
            thumbDetectionMode: .disabledFallback
        )
        let recognizer = recognizer(.thumbFourFingerScale, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: scaleStart(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: scaleStart(), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: scaleEnd(), time: 1.22))

        XCTAssertEqual(gestures.map(\.kind), [.thumbFourFingerScale])
    }

    func testDrawingMatchesConfiguredTemplateOnRelease() {
        let recognizer = recognizer(.fiveFingerDrawing)

        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.2, 0.1), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.2, 0.1), time: 1.05)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.2, 0.8), time: 1.4)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.7, 0.8), time: 1.7)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.8))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerDrawing])
    }

    func testWholeHandTapTriggersAfterRelease() {
        let recognizer = recognizer(.wholeHandTap)

        XCTAssertTrue(recognizer.process(frame(touches: wholeHandTouches(at: 0.5, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: wholeHandTouches(at: 0.5, 0.5), time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.12))

        XCTAssertEqual(gestures.map(\.kind), [.wholeHandTap])
    }

    func testWholeHandTapBeatsFiveFingerTapWhenLargeFiveContactsMatchBoth() {
        var wholeRule = fiveAndMoreRule(.wholeHandTap)
        wholeRule.wholeHandTap.minContactCount = 5
        wholeRule.wholeHandTap.minTotalContactArea = 1.4
        let recognizer = GestureRecognizer(configuration: GestureConfiguration(triggers: [
            trigger(.fiveFingerTap),
            trigger(.wholeHandTap, rule: wholeRule)
        ]))

        XCTAssertTrue(recognizer.process(frame(touches: largeFiveTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: largeFiveTouches(), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.12))

        XCTAssertEqual(gestures.map(\.kind), [.wholeHandTap])
    }

    func testScaleBeatsSwipeWhenScaleDeltaIsClear() {
        let recognizer = GestureRecognizer(configuration: GestureConfiguration(triggers: [
            trigger(.fiveFingerSwipe, rule: swipeRightRule()),
            trigger(.thumbFourFingerScale, rule: spreadScaleRule())
        ]))

        XCTAssertTrue(recognizer.process(frame(touches: scaleSwipeStart(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: scaleSwipeStart(), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: scaleSwipeEnd(), time: 1.22))

        XCTAssertEqual(gestures.map(\.kind), [.thumbFourFingerScale])
    }

    func testSwipeWinsWhenScaleDeltaIsSmall() {
        let recognizer = GestureRecognizer(configuration: GestureConfiguration(triggers: [
            trigger(.thumbFourFingerScale, rule: spreadScaleRule()),
            trigger(.fiveFingerSwipe, rule: swipeRightRule())
        ]))

        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.25, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fiveTouches(at: 0.25, 0.5), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: fiveTouches(at: 0.55, 0.5), time: 1.22))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerSwipe])
    }

    func testConfigurationCodableRoundTripsFiveAndWholeHandTriggers() throws {
        let configuration = GestureConfiguration(triggers: [
            trigger(.fiveFingerSwipe, rule: swipeRightRule()),
            trigger(.wholeHandTap)
        ])

        let encoded = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(GestureConfiguration.self, from: encoded)

        XCTAssertEqual(decoded, configuration)
        XCTAssertNoThrow(try decoded.validate())
    }

    private func recognizer(_ type: GestureTriggerType, rule: FiveAndMoreFingerGestureRule? = nil) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [trigger(type, rule: rule)]))
    }

    private func trigger(_ type: GestureTriggerType, rule: FiveAndMoreFingerGestureRule? = nil) -> GestureRule {
        .fiveAndMoreFinger(id: type.rawValue, type: type, rule: rule ?? fiveAndMoreRule(type))
    }

    private func fiveAndMoreRule(_ type: GestureTriggerType) -> FiveAndMoreFingerGestureRule {
        guard case .fiveAndMoreFinger(_, _, let rule) = type.defaultTrigger(id: type.rawValue, ordinal: 1) else {
            XCTFail("Expected five and more finger default")
            return FiveAndMoreFingerGestureRule(name: "broken", isEnabled: false, cooldownMilliseconds: 650, actions: [])
        }
        return rule
    }

    private func swipeRightRule() -> FiveAndMoreFingerGestureRule {
        var rule = fiveAndMoreRule(.fiveFingerSwipe)
        rule.swipe = ThreeFingerSwipeOptions(direction: .right, minimumTravel: 0.12, minimumVelocity: 0.35)
        return rule
    }

    private func spreadScaleRule() -> FiveAndMoreFingerGestureRule {
        var rule = fiveAndMoreRule(.thumbFourFingerScale)
        rule.scale = ThreeFingerScaleOptions(
            direction: .spreadOut,
            minimumScaleDelta: 0.22,
            thumbDetectionMode: .disabledFallback
        )
        return rule
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func fiveTouches(at x: Double, _ y: Double, pressure: Double = 0.2, size: Double = 0.2) -> [TouchPoint] {
        [-0.08, -0.04, 0, 0.04, 0.08].enumerated().map { index, offset in
            touch(id: index + 1, x: x + offset, y: y, pressure: pressure, size: size)
        }
    }

    private func wholeHandTouches(at x: Double, _ y: Double) -> [TouchPoint] {
        let offsets = [(-0.15, -0.05), (-0.1, 0.05), (-0.05, -0.08), (0, 0.08),
                       (0.05, -0.05), (0.1, 0.05), (0.15, -0.02), (0.0, -0.15)]
        return offsets.enumerated().map { index, offset in
            touch(id: index + 1, x: x + offset.0, y: y + offset.1, size: 0.22)
        }
    }

    private func largeFiveTouches() -> [TouchPoint] {
        fiveTouches(at: 0.5, 0.5, size: 0.32)
    }

    private func scaleStart() -> [TouchPoint] {
        [0.38, 0.44, 0.50, 0.56, 0.62].enumerated().map { index, x in
            touch(id: index + 1, x: x, y: 0.5)
        }
    }

    private func scaleEnd() -> [TouchPoint] {
        [0.18, 0.36, 0.50, 0.64, 0.82].enumerated().map { index, x in
            touch(id: index + 1, x: x, y: 0.5)
        }
    }

    private func scaleSwipeStart() -> [TouchPoint] {
        [0.20, 0.25, 0.30, 0.35, 0.40].enumerated().map { index, x in
            touch(id: index + 1, x: x, y: 0.5)
        }
    }

    private func scaleSwipeEnd() -> [TouchPoint] {
        [0.18, 0.35, 0.50, 0.65, 0.82].enumerated().map { index, x in
            touch(id: index + 1, x: x, y: 0.5)
        }
    }

    private func touch(
        id: Int,
        x: Double,
        y: Double,
        pressure: Double = 0.2,
        size: Double = 0.2
    ) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: pressure, size: size)
    }
}
