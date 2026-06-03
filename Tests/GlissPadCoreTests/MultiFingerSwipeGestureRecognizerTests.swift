@testable import GlissPadCore
import Foundation
import XCTest

final class MultiFingerSwipeGestureRecognizerTests: XCTestCase {
    func testFreeSwipeTriggersRightMotionFromAnyStart() {
        let recognizer = recognizer(type: .freeformTwoFingerSwipe, rule: freeRule())

        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.18, x2: 0.28), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.42, x2: 0.52), time: 1.1)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.2))

        XCTAssertEqual(gestures.map(\.kind), [.freeformTwoFingerSwipe])
    }

    func testFreeSwipeRejectsOppositeDirection() {
        let recognizer = recognizer(type: .freeformTwoFingerSwipe, rule: freeRule())

        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.72, x2: 0.82), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.36, x2: 0.46), time: 1.1)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.2))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testRegionSwipeRequiresStartAndEndRegions() {
        let recognizer = recognizer(type: .regionTwoFingerSwipe, rule: regionRule())

        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.08, x2: 0.16), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.68, x2: 0.76), time: 1.1)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.2))

        XCTAssertEqual(gestures.map(\.kind), [.regionTwoFingerSwipe])
    }

    func testRegionSwipeRejectsWrongEndRegion() {
        let recognizer = recognizer(type: .regionTwoFingerSwipe, rule: regionRule())

        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.08, x2: 0.16), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.38, x2: 0.46), time: 1.1)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.2))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testRegionSwipeAllowsStaggeredFingerRelease() {
        let recognizer = recognizer(type: .regionTwoFingerSwipe, rule: regionRule())

        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.08, x2: 0.16), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(x1: 0.68, x2: 0.76), time: 1.1)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.68)], time: 1.12)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.14))

        XCTAssertEqual(gestures.map(\.kind), [.regionTwoFingerSwipe])
    }

    private func recognizer(
        type: GestureTriggerType,
        rule: MultiFingerSwipeGestureRule
    ) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(
            triggers: [.multiFingerSwipe(id: type.rawValue, type: type, rule: rule)]
        ))
    }

    private func freeRule() -> MultiFingerSwipeGestureRule {
        MultiFingerSwipeGestureRule(
            name: "Free Right",
            isEnabled: true,
            pathPreset: .right,
            pointTolerance: 0.16,
            minimumTravel: 0.18,
            cooldownMilliseconds: 650,
            actions: actions()
        )
    }

    private func regionRule() -> MultiFingerSwipeGestureRule {
        MultiFingerSwipeGestureRule(
            name: "Region Right",
            isEnabled: true,
            pathPreset: .right,
            pointTolerance: 0.16,
            minimumTravel: 0.18,
            startRegion: NormalizedRegion(minX: 0.0, maxX: 0.2, minY: 0.3, maxY: 0.7),
            endRegion: NormalizedRegion(minX: 0.64, maxX: 0.82, minY: 0.3, maxY: 0.7),
            cooldownMilliseconds: 650,
            actions: actions()
        )
    }

    private func actions() -> [GestureAction] {
        GestureActionsCoding.scriptActions([ScriptAction(language: .appleScript, script: "return true")])
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func touches(x1: Double, x2: Double) -> [TouchPoint] {
        [touch(id: 1, x: x1), touch(id: 2, x: x2)]
    }

    private func touch(id: Int, x: Double) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: 0.5), pressure: 0.7, size: 0.2)
    }
}
