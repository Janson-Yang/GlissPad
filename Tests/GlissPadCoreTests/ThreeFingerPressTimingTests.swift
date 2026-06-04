@testable import GlissPadCore
import Foundation
import XCTest

final class ThreeFingerPressTimingTests: XCTestCase {
    func testPressUpTriggersWhenReleaseStartsOneFingerAtATime() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: pressTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: pressTouches(), time: 1.04)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: pressTouches(), time: 1.06)).isEmpty)
        let gestures = recognizer.process(frame(touches: releasedOneFingerTouches(), time: 1.08))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerPress])
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.10)).isEmpty)
    }

    func testPressUpDoesNotTriggerWithoutSatisfiedPressure() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: pressTouches(pressure: 0.3), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: pressTouches(pressure: 0.3), time: 1.04)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: pressTouches(pressure: 0.3), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: releasedOneFingerTouches(pressure: 0.3), time: 1.08)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.10)).isEmpty)
    }

    private func recognizer() -> GestureRecognizer {
        var rule = threeFingerPressRule()
        rule.press = ThreeFingerPressOptions(level: .force, triggerTiming: .pressUp)
        return GestureRecognizer(configuration: GestureConfiguration(triggers: [
            .threeFinger(id: "press", type: .threeFingerPress, rule: rule)
        ]))
    }

    private func threeFingerPressRule() -> ThreeFingerGestureRule {
        guard case .threeFinger(_, _, let rule) = GestureTriggerType.threeFingerPress.defaultTrigger(
            id: "press",
            ordinal: 1
        ) else {
            XCTFail("Expected three finger press default")
            return ThreeFingerGestureRule(name: "broken", isEnabled: false, cooldownMilliseconds: 650, actions: [])
        }
        return rule
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func pressTouches(pressure: Double = TrackpadPressureThreshold.forceClick) -> [TouchPoint] {
        [
            touch(id: 1, x: 0.35, pressure: pressure),
            touch(id: 2, x: 0.50, pressure: pressure),
            touch(id: 3, x: 0.65, pressure: pressure)
        ]
    }

    private func releasedOneFingerTouches(pressure: Double = TrackpadPressureThreshold.forceClick) -> [TouchPoint] {
        [
            touch(id: 1, x: 0.35, pressure: pressure),
            touch(id: 2, x: 0.50, pressure: pressure)
        ]
    }

    private func touch(id: Int, x: Double, pressure: Double) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: 0.5),
            pressure: pressure,
            size: 0.2
        )
    }
}
