@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerShapeRecognizerTests: XCTestCase {
    func testSquareTriggersAfterClosedSquareRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(kind: .oneFingerSquare, shape: .square))

        processPath(squarePoints, on: recognizer)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.6))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerSquare])
        XCTAssertEqual(gestures.first?.name, "Square")
    }

    func testTriangleTriggersAfterClosedTriangleRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(kind: .oneFingerTriangle, shape: .triangle))

        processPath(trianglePoints, on: recognizer)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.6))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerTriangle])
    }

    func testOpenPathDoesNotTriggerShape() {
        let recognizer = GestureRecognizer(configuration: configuration(kind: .oneFingerSquare, shape: .square))

        processPath(Array(squarePoints.dropLast()), on: recognizer)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.6))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testTriangleDoesNotTriggerSquareRule() {
        let recognizer = GestureRecognizer(configuration: configuration(kind: .oneFingerSquare, shape: .square))

        processPath(trianglePoints, on: recognizer)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.6))

        XCTAssertTrue(gestures.isEmpty)
    }

    private var squarePoints: [NormalizedPoint] {
        [
            NormalizedPoint(x: 0.3, y: 0.3),
            NormalizedPoint(x: 0.5, y: 0.3),
            NormalizedPoint(x: 0.7, y: 0.3),
            NormalizedPoint(x: 0.7, y: 0.5),
            NormalizedPoint(x: 0.7, y: 0.7),
            NormalizedPoint(x: 0.5, y: 0.7),
            NormalizedPoint(x: 0.3, y: 0.7),
            NormalizedPoint(x: 0.3, y: 0.5),
            NormalizedPoint(x: 0.3, y: 0.3)
        ]
    }

    private var trianglePoints: [NormalizedPoint] {
        [
            NormalizedPoint(x: 0.5, y: 0.25),
            NormalizedPoint(x: 0.62, y: 0.45),
            NormalizedPoint(x: 0.75, y: 0.7),
            NormalizedPoint(x: 0.5, y: 0.7),
            NormalizedPoint(x: 0.25, y: 0.7),
            NormalizedPoint(x: 0.38, y: 0.45),
            NormalizedPoint(x: 0.5, y: 0.25)
        ]
    }

    private func configuration(kind: GestureTriggerType, shape: ShapeGestureKind) -> GestureConfiguration {
        let rule = ShapeGestureRule(
            name: shape == .square ? "Square" : "Triangle",
            isEnabled: true,
            shape: shape,
            cornerTolerance: 0.14,
            cooldownMilliseconds: 650,
            actions: [.script(ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript))]
        )
        return GestureConfiguration(triggers: [.shape(id: shape.rawValue, type: kind, rule: rule)])
    }

    private func processPath(_ points: [NormalizedPoint], on recognizer: GestureRecognizer) {
        for (index, point) in points.enumerated() {
            let timestamp = 1.0 + Double(index) * 0.04
            _ = recognizer.process(frame(touches: [touch(id: 1, point: point)], timestamp: timestamp))
        }
    }

    private func frame(touches: [TouchPoint], timestamp: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: timestamp, frameNumber: Int(timestamp * 100))
    }

    private func touch(id: Int, point: NormalizedPoint) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: point, pressure: 0.2, size: 0.2)
    }
}
