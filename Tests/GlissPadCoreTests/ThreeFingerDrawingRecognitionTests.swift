@testable import GlissPadCore
import Foundation
import XCTest

final class ThreeFingerDrawingRecognitionTests: XCTestCase {
    func testDrawingTriggersWhenReleaseStartsOneFingerAtATime() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.04)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.8), time: 1.4)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.7, 0.8), time: 1.7)).isEmpty)
        let gestures = recognizer.process(frame(touches: Array(touches(at: 0.7, 0.8).prefix(2)), time: 1.8))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerDrawing])
    }

    func testDrawingAllowsHumanInitialFingerGap() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.16, y: 0.1)], time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: Array(touches(at: 0.2, 0.1).prefix(2)), time: 1.12)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.22)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.27)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.8), time: 1.45)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.7, 0.8), time: 1.7)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.8))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerDrawing])
    }

    func testAllFingersAveragePathSourceMatchesDrawingPath() {
        var rule = drawingRule()
        rule.drawing.pathSource = .allFingersAverage
        let recognizer = recognizer(rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.04)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.8), time: 1.4)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.7, 0.8), time: 1.7)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.8))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerDrawing])
    }

    private func recognizer(rule: ThreeFingerGestureRule? = nil) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [
            .threeFinger(id: "drawing", type: .threeFingerDrawing, rule: rule ?? drawingRule())
        ]))
    }

    private func drawingRule() -> ThreeFingerGestureRule {
        guard case .threeFinger(_, _, let rule) = GestureTriggerType.threeFingerDrawing.defaultTrigger(
            id: "drawing",
            ordinal: 1
        ) else {
            return ThreeFingerGestureRule(name: "Drawing", isEnabled: true, cooldownMilliseconds: 650, actions: [])
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

    private func touch(id: Int, x: Double, y: Double) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: 0.2, size: 0.2)
    }
}
