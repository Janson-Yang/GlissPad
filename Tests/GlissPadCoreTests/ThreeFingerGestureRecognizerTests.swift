@testable import GlissPadCore
import XCTest

final class ThreeFingerGestureRecognizerTests: XCTestCase {
    func testTouchStartTriggersWhenThreeFingersArrive() {
        let recognizer = recognizer(.threeFingerTouch)

        let gestures = recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.0))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTouch])
    }

    func testTapTriggersAfterRelease() {
        let recognizer = recognizer(.threeFingerTap)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.1))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTap])
    }

    func testPressCanRequireRightFingerPressureBias() {
        var rule = threeFingerRule(.threeFingerPress)
        rule.press = ThreeFingerPressOptions(level: .force, pressureBias: .right)
        let recognizer = recognizer(.threeFingerPress, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: biasedPressures(), time: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: biasedPressures(), time: 1.02))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerPress])
    }

    func testSwipeTriggersOnDirectionalMovement() {
        var rule = threeFingerRule(.threeFingerSwipe)
        rule.swipe = ThreeFingerSwipeOptions(direction: .right, minimumTravel: 0.16, minimumVelocity: 0.5)
        let recognizer = recognizer(.threeFingerSwipe, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.25, 0.5), time: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(at: 0.55, 0.5), time: 1.2))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerSwipe])
    }

    func testTipTapTriggersWhenThirdFingerTapsWhileTwoStayFixed() {
        var rule = threeFingerRule(.threeFingerTipTap)
        rule.tipTap = ThreeFingerTipTapOptions(tapPosition: .right)
        let recognizer = recognizer(.threeFingerTipTap, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.5)], time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.14))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipTap])
    }

    func testTipSwipeTriggersWhenThirdFingerMovesAndTwoStayFixed() {
        let recognizer = recognizer(.threeFingerTipSwipe)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.5)], time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.3)], time: 1.26))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipSwipe])
    }

    func testScaleBeatsSwipeWhenBothMatchSameFrame() {
        let recognizer = GestureRecognizer(configuration: GestureConfiguration(triggers: [
            trigger(.threeFingerSwipe),
            trigger(.thumbTwoFingerScale)
        ]))

        XCTAssertTrue(recognizer.process(frame(touches: spreadStart(), time: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: spreadEnd(), time: 1.2))

        XCTAssertEqual(gestures.map(\.kind), [.thumbTwoFingerScale])
    }

    func testDrawingMatchesConfiguredTemplateOnRelease() {
        let recognizer = recognizer(.threeFingerDrawing)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.8), time: 1.4)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.7, 0.8), time: 1.7)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.8))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerDrawing])
    }

    private func recognizer(_ type: GestureTriggerType, rule: ThreeFingerGestureRule? = nil) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [trigger(type, rule: rule)]))
    }

    private func trigger(_ type: GestureTriggerType, rule: ThreeFingerGestureRule? = nil) -> GestureRule {
        .threeFinger(id: type.rawValue, type: type, rule: rule ?? threeFingerRule(type))
    }

    private func threeFingerRule(_ type: GestureTriggerType) -> ThreeFingerGestureRule {
        guard case .threeFinger(_, _, let rule) = type.defaultTrigger(id: type.rawValue, ordinal: 1) else {
            XCTFail("Expected three finger default")
            return ThreeFingerGestureRule(name: "broken", isEnabled: false, cooldownMilliseconds: 650, actions: [])
        }
        return rule
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func touches(at x: Double, _ y: Double) -> [TouchPoint] {
        [
            touch(id: 1, x: x - 0.04, y: y),
            touch(id: 2, x: x, y: y),
            touch(id: 3, x: x + 0.04, y: y)
        ]
    }

    private func touch(id: Int, x: Double, y: Double, pressure: Double = 0.2) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: pressure, size: 0.2)
    }

    private func biasedPressures() -> [TouchPoint] {
        [
            touch(id: 1, x: 0.2, y: 0.5, pressure: 0.2),
            touch(id: 2, x: 0.4, y: 0.5, pressure: 0.2),
            touch(id: 3, x: 0.6, y: 0.5, pressure: 1.5)
        ]
    }

    private func baseTouches() -> [TouchPoint] {
        [touch(id: 1, x: 0.3, y: 0.5), touch(id: 2, x: 0.5, y: 0.5)]
    }

    private func spreadStart() -> [TouchPoint] {
        [touch(id: 1, x: 0.2, y: 0.5), touch(id: 2, x: 0.25, y: 0.5), touch(id: 3, x: 0.3, y: 0.5)]
    }

    private func spreadEnd() -> [TouchPoint] {
        [touch(id: 1, x: 0.3, y: 0.5), touch(id: 2, x: 0.6, y: 0.5), touch(id: 3, x: 0.9, y: 0.5)]
    }
}
