@testable import GlissPadCore
import XCTest

final class ThreeFingerTipSwipeFixedFingerTests: XCTestCase {
    func testTipSwipeInfersSlidingFingerWhenAllTouchesStartTogether() {
        var rule = threeFingerRule()
        rule.tipSwipe = ThreeFingerTipSwipeOptions(direction: .up, minimumVelocity: 0.3)
        let recognizer = recognizer(rule)

        XCTAssertTrue(recognizer.process(frame(touches: threeTouches(activeY: 0.55), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: threeTouches(activeY: 0.55), time: 1.2)).isEmpty)
        let gestures = recognizer.process(frame(touches: threeTouches(activeY: 0.75), time: 1.3))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipSwipe])
    }

    func testTipSwipeDownUsesOppositeVerticalDirection() {
        var rule = threeFingerRule()
        rule.tipSwipe = ThreeFingerTipSwipeOptions(direction: .down, minimumVelocity: 0.3)
        let recognizer = recognizer(rule)

        XCTAssertTrue(recognizer.process(frame(touches: threeTouches(activeY: 0.55), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: threeTouches(activeY: 0.55), time: 1.2)).isEmpty)
        let gestures = recognizer.process(frame(touches: threeTouches(activeY: 0.35), time: 1.3))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipSwipe])
    }

    func testTipSwipeDoesNotTreatWholeHandSwipeAsTipSwipe() {
        var rule = threeFingerRule()
        rule.tipSwipe = ThreeFingerTipSwipeOptions(direction: .up, minimumVelocity: 0.3)
        let recognizer = recognizer(rule)

        XCTAssertTrue(recognizer.process(frame(touches: threeTouches(activeY: 0.55), time: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: threeTouches(y: 0.35), time: 1.3))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testTipSwipeCanUseOneFixedFingerAndRightSlidingFinger() {
        var rule = threeFingerRule()
        rule.tipSwipe = ThreeFingerTipSwipeOptions(
            fixedFingers: 1,
            activeFinger: .right,
            direction: .up,
            minimumVelocity: 0.3
        )
        let recognizer = recognizer(rule)

        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.35)], time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: twoTouches(activeY: 0.55), time: 1.06)).isEmpty)
        let gestures = recognizer.process(frame(touches: twoTouches(activeY: 0.75), time: 1.36))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipSwipe])
    }

    func testOneFixedFingerRejectsMiddleSlidingFingerConfiguration() {
        var rule = threeFingerRule()
        rule.tipSwipe = ThreeFingerTipSwipeOptions(fixedFingers: 1, activeFinger: .middle)

        XCTAssertThrowsError(try rule.validate(name: "tipSwipe", type: .threeFingerTipSwipe))
    }

    private func recognizer(_ rule: ThreeFingerGestureRule) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [
            .threeFinger(id: "tip-swipe", type: .threeFingerTipSwipe, rule: rule)
        ]))
    }

    private func threeFingerRule() -> ThreeFingerGestureRule {
        ThreeFingerGestureRule(
            name: "TipSwipe",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(title: "ok"))]
        )
    }

    private func twoTouches(activeY: Double) -> [TouchPoint] {
        [touch(id: 1, x: 0.35), touch(id: 2, x: 0.65, y: activeY)]
    }

    private func threeTouches(activeY: Double) -> [TouchPoint] {
        [touch(id: 1, x: 0.25), touch(id: 2, x: 0.5), touch(id: 3, x: 0.75, y: activeY)]
    }

    private func threeTouches(y: Double) -> [TouchPoint] {
        [touch(id: 1, x: 0.25, y: y), touch(id: 2, x: 0.5, y: y), touch(id: 3, x: 0.75, y: y)]
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func touch(id: Int, x: Double, y: Double = 0.55) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: y),
            pressure: 0.2,
            size: 0.2
        )
    }
}
