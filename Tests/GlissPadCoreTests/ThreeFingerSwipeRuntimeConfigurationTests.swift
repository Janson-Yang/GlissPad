@testable import GlissPadCore
import Foundation
import XCTest

final class ThreeFingerSwipeRuntimeConfigurationTests: XCTestCase {
    func testLeftSwipeTriggersWithFullStartAndEndRegions() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(x: 0.80, time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(x: 0.80, time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(x: 0.48, time: 1.24))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerSwipe])
    }

    func testLeftSwipeTriggersWhenEndpointArrivesDuringFingerRelease() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(x: 0.80, time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(x: 0.80, time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: twoTouches(at: 0.48), time: 1.24))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerSwipe])
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.26)).isEmpty)
    }

    func testLeftSwipeUsesConfiguredEndRegionOnRelease() {
        let recognizer = recognizer(
            startRegion: NormalizedRegion(minX: 0.70, maxX: 1.00, minY: 0, maxY: 1),
            endRegion: NormalizedRegion(minX: 0.00, maxX: 0.55, minY: 0, maxY: 1)
        )

        XCTAssertTrue(recognizer.process(frame(x: 0.84, time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(x: 0.84, time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: twoTouches(at: 0.46), time: 1.24))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerSwipe])
    }

    func testLeftSwipeUsesBreakTouchEndpointWhenAllFingersReleaseTogether() {
        let recognizer = recognizer(
            startRegion: NormalizedRegion(minX: 0.70, maxX: 1.00, minY: 0, maxY: 1),
            endRegion: NormalizedRegion(minX: 0.00, maxX: 0.55, minY: 0, maxY: 1)
        )

        XCTAssertTrue(recognizer.process(frame(x: 0.84, time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(x: 0.84, time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: breakTouches(at: 0.46), time: 1.24))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerSwipe])
    }

    private func recognizer(
        startRegion: NormalizedRegion = NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1),
        endRegion: NormalizedRegion = NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1)
    ) -> GestureRecognizer {
        var rule = threeFingerSwipeRule()
        rule.common = ThreeFingerCommonOptions(startRegion: startRegion, endRegion: endRegion)
        rule.swipe = ThreeFingerSwipeOptions(
            direction: .left,
            minimumTravel: 0.18,
            minimumVelocity: 0.9,
            directionToleranceDegrees: 35,
            triggerTiming: .thresholdReached
        )
        return GestureRecognizer(configuration: GestureConfiguration(triggers: [
            .threeFinger(id: "left-swipe", type: .threeFingerSwipe, rule: rule)
        ]))
    }

    private func threeFingerSwipeRule() -> ThreeFingerGestureRule {
        guard case .threeFinger(_, _, let rule) = GestureTriggerType.threeFingerSwipe.defaultTrigger(
            id: "left-swipe",
            ordinal: 1
        ) else {
            XCTFail("Expected three finger swipe default")
            return ThreeFingerGestureRule(name: "broken", isEnabled: false, cooldownMilliseconds: 650, actions: [])
        }
        return rule
    }

    private func frame(x: Double, time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: [
            touch(id: 1, x: x - 0.04),
            touch(id: 2, x: x),
            touch(id: 3, x: x + 0.04)
        ], timestamp: time, frameNumber: Int(time * 100))
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func twoTouches(at x: Double) -> [TouchPoint] {
        [touch(id: 1, x: x - 0.04), touch(id: 2, x: x)]
    }

    private func breakTouches(at x: Double) -> [TouchPoint] {
        [
            touch(id: 1, x: x - 0.04, state: .breakTouch),
            touch(id: 2, x: x, state: .breakTouch),
            touch(id: 3, x: x + 0.04, state: .breakTouch)
        ]
    }

    private func touch(id: Int, x: Double, state: TouchState = .touching) -> TouchPoint {
        TouchPoint(
            id: id,
            state: state,
            position: NormalizedPoint(x: x, y: 0.5),
            pressure: TrackpadPressureThreshold.touch,
            size: 0.2
        )
    }
}
