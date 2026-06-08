@testable import GlissPadCore
import Foundation
import XCTest

final class FourFingerGestureRecognizerTests: XCTestCase {
    func testTouchStartTriggersWhenFourFingersArrive() {
        let recognizer = recognizer(.fourFingerTouch)

        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: fourTouches(at: 0.4, 0.5), time: 1.05))

        XCTAssertEqual(gestures.map(\.kind), [.fourFingerTouch])
    }

    func testTapTriggersAfterRelease() {
        let recognizer = recognizer(.fourFingerTap)

        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.4, 0.5), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.12))

        XCTAssertEqual(gestures.map(\.kind), [.fourFingerTap])
    }

    func testPressTriggersAfterFourFingerPressureThreshold() {
        var rule = fourFingerRule(.fourFingerPress)
        rule.press = FourFingerPressOptions(level: .normal, minimumPressure: 0.5)
        let recognizer = recognizer(.fourFingerPress, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.4, 0.5, pressure: 0.8), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.4, 0.5, pressure: 0.8), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: fourTouches(at: 0.4, 0.5, pressure: 0.8), time: 1.07))

        XCTAssertEqual(gestures.map(\.kind), [.fourFingerPress])
    }

    func testSwipeTriggersOnFourFingerDirectionalMovement() {
        var rule = fourFingerRule(.fourFingerSwipe)
        rule.swipe = ThreeFingerSwipeOptions(direction: .right, minimumTravel: 0.16, minimumVelocity: 0.5)
        let recognizer = recognizer(.fourFingerSwipe, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.25, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.25, 0.5), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: fourTouches(at: 0.55, 0.5), time: 1.22))

        XCTAssertEqual(gestures.map(\.kind), [.fourFingerSwipe])
    }

    func testSwipeUpUsesTrackpadUpDirection() {
        var rule = fourFingerRule(.fourFingerSwipe)
        rule.swipe = ThreeFingerSwipeOptions(direction: .up, minimumTravel: 0.16, minimumVelocity: 0.5)
        let recognizer = recognizer(.fourFingerSwipe, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.5, 0.25), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.5, 0.25), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: fourTouches(at: 0.5, 0.55), time: 1.22))

        XCTAssertEqual(gestures.map(\.kind), [.fourFingerSwipe])
    }

    func testSwipeDownUsesTrackpadDownDirection() {
        var rule = fourFingerRule(.fourFingerSwipe)
        rule.swipe = ThreeFingerSwipeOptions(direction: .down, minimumTravel: 0.16, minimumVelocity: 0.5)
        let recognizer = recognizer(.fourFingerSwipe, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.5, 0.55), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.5, 0.55), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: fourTouches(at: 0.5, 0.25), time: 1.22))

        XCTAssertEqual(gestures.map(\.kind), [.fourFingerSwipe])
    }

    func testScaleTriggersOnFourFingerSpread() {
        var rule = fourFingerRule(.thumbThreeFingerScale)
        rule.scale = ThreeFingerScaleOptions(direction: .spreadOut, minimumScaleDelta: 0.18)
        let recognizer = recognizer(.thumbThreeFingerScale, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: spreadStart(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: spreadStart(), time: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: spreadEnd(), time: 1.22))

        XCTAssertEqual(gestures.map(\.kind), [.thumbThreeFingerScale])
    }

    func testScaleReleaseTriggersForEitherPinchAndSpread() {
        assertScaleReleaseTriggers(start: spreadStart(), end: spreadEnd(), releasedEnd: spreadEndWithReleasedFinger())
        assertScaleReleaseTriggers(start: spreadEnd(), end: spreadStart(), releasedEnd: spreadStartWithReleasedFinger())
    }

    func testTipTapTriggersWhenFourthFingerTapsBesideThreeFixedFingers() {
        var rule = fourFingerRule(.fourFingerTipTap)
        rule.tipTap = FourFingerTipTapOptions(tapSide: .right)
        let recognizer = recognizer(.fourFingerTipTap, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: fixedTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fixedTouches(), time: 1.07)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fixedTouches() + [touch(id: 4, x: 0.7, y: 0.5)], time: 1.1)).isEmpty)
        let gestures = recognizer.process(frame(touches: fixedTouches(), time: 1.16))

        XCTAssertEqual(gestures.map(\.kind), [.fourFingerTipTap])
    }

    func testDrawingMatchesConfiguredTemplateOnRelease() {
        let recognizer = recognizer(.fourFingerDrawing)

        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.2, 0.1), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.2, 0.1), time: 1.05)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.2, 0.8), time: 1.4)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: fourTouches(at: 0.7, 0.8), time: 1.7)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.8))

        XCTAssertEqual(gestures.map(\.kind), [.fourFingerDrawing])
    }

    private func recognizer(_ type: GestureTriggerType, rule: FourFingerGestureRule? = nil) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [trigger(type, rule: rule)]))
    }

    private func trigger(_ type: GestureTriggerType, rule: FourFingerGestureRule? = nil) -> GestureRule {
        .fourFinger(id: type.rawValue, type: type, rule: rule ?? fourFingerRule(type))
    }

    private func fourFingerRule(_ type: GestureTriggerType) -> FourFingerGestureRule {
        guard case .fourFinger(_, _, let rule) = type.defaultTrigger(id: type.rawValue, ordinal: 1) else {
            XCTFail("Expected four finger default")
            return FourFingerGestureRule(name: "broken", isEnabled: false, cooldownMilliseconds: 650, actions: [])
        }
        return rule
    }

    private func assertScaleReleaseTriggers(start: [TouchPoint], end: [TouchPoint], releasedEnd: [TouchPoint]) {
        var rule = fourFingerRule(.thumbThreeFingerScale)
        rule.scale = ThreeFingerScaleOptions(direction: .any, minimumScaleDelta: 0.18, triggerTiming: .release)
        let recognizer = recognizer(.thumbThreeFingerScale, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: start, time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: start, time: 1.05)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: end, time: 1.22)).isEmpty)
        let gestures = recognizer.process(frame(touches: releasedEnd, time: 1.26))

        XCTAssertEqual(gestures.map(\.kind), [.thumbThreeFingerScale])
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func fourTouches(at x: Double, _ y: Double, pressure: Double = 0.2) -> [TouchPoint] {
        [
            touch(id: 1, x: x - 0.06, y: y, pressure: pressure),
            touch(id: 2, x: x - 0.02, y: y, pressure: pressure),
            touch(id: 3, x: x + 0.02, y: y, pressure: pressure),
            touch(id: 4, x: x + 0.06, y: y, pressure: pressure)
        ]
    }

    private func fixedTouches() -> [TouchPoint] {
        [
            touch(id: 1, x: 0.35, y: 0.5),
            touch(id: 2, x: 0.45, y: 0.5),
            touch(id: 3, x: 0.55, y: 0.5)
        ]
    }

    private func spreadStart() -> [TouchPoint] {
        [
            touch(id: 1, x: 0.35, y: 0.45),
            touch(id: 2, x: 0.45, y: 0.55),
            touch(id: 3, x: 0.55, y: 0.45),
            touch(id: 4, x: 0.65, y: 0.55)
        ]
    }

    private func spreadEnd() -> [TouchPoint] {
        [
            touch(id: 1, x: 0.2, y: 0.35),
            touch(id: 2, x: 0.4, y: 0.65),
            touch(id: 3, x: 0.6, y: 0.35),
            touch(id: 4, x: 0.8, y: 0.65)
        ]
    }

    private func spreadEndWithReleasedFinger() -> [TouchPoint] {
        spreadEnd().map { $0.id == 4 ? released($0) : $0 }
    }

    private func spreadStartWithReleasedFinger() -> [TouchPoint] {
        spreadStart().map { $0.id == 4 ? released($0) : $0 }
    }

    private func released(_ touch: TouchPoint) -> TouchPoint {
        TouchPoint(id: touch.id, state: .breakTouch, position: touch.position, pressure: touch.pressure, size: touch.size)
    }

    private func touch(id: Int, x: Double, y: Double, pressure: Double = 0.2) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: pressure, size: 0.2)
    }
}
