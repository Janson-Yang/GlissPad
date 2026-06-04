@testable import GlissPadCore
import XCTest

final class ThreeFingerTipTapOrderTests: XCTestCase {
    func testTouchOrderUsesInputFrameOrderRatherThanSystemTouchID() {
        var rule = threeFingerRule()
        rule.tipTap = ThreeFingerTipTapOptions(tapPosition: .middle, positionReference: .touchOrder)
        let recognizer = recognizer(rule)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touchesWithMiddleTap(), time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.14))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipTap])
    }

    func testTrackpadPositionStillUsesHorizontalFingerPosition() {
        var rule = threeFingerRule()
        rule.tipTap = ThreeFingerTipTapOptions(tapPosition: .left, positionReference: .trackpad)
        let recognizer = recognizer(rule)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [tapTouch(id: 1)], time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.14))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipTap])
    }

    func testAutoTapFingerAllowsAnyTrackpadPosition() {
        var rule = threeFingerRule()
        rule.tipTap = ThreeFingerTipTapOptions(tapPosition: .auto, positionReference: .trackpad)
        let recognizer = recognizer(rule)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [tapTouch(id: 1)], time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.14))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipTap])
    }

    private func recognizer(_ rule: ThreeFingerGestureRule) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [
            .threeFinger(id: "tip-tap", type: .threeFingerTipTap, rule: rule)
        ]))
    }

    private func threeFingerRule() -> ThreeFingerGestureRule {
        ThreeFingerGestureRule(
            name: "TipTap",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(title: "ok"))]
        )
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func baseTouches() -> [TouchPoint] {
        [
            touch(id: 10, x: 0.35),
            touch(id: 20, x: 0.55)
        ]
    }

    private func tapTouch(id: Int) -> TouchPoint {
        touch(id: id, x: 0.25)
    }

    private func touchesWithMiddleTap() -> [TouchPoint] {
        [baseTouches()[0], tapTouch(id: 1), baseTouches()[1]]
    }

    private func touch(id: Int, x: Double) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: 0.5),
            pressure: 0.2,
            size: 0.2
        )
    }
}
