@testable import GlissPadCore
import XCTest

final class ThreeFingerTipSwipeFixedFingerTests: XCTestCase {
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
        let gestures = recognizer.process(frame(touches: twoTouches(activeY: 0.35), time: 1.36))

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
