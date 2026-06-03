@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerDrawnPathRecognizerTests: XCTestCase {
    func testTriggersAfterFollowingDrawnPathAndRelease() {
        let recognizer = GestureRecognizer(configuration: configuration())

        pathPoints.enumerated().forEach { index, point in
            XCTAssertTrue(recognizer.process(touchFrame(point, timestamp: 1.0 + Double(index) * 0.02)).isEmpty)
        }
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.5))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerDrawnPath])
    }

    func testRejectsReverseDirection() {
        let recognizer = GestureRecognizer(configuration: configuration())

        pathPoints.reversed().enumerated().forEach { index, point in
            XCTAssertTrue(recognizer.process(touchFrame(point, timestamp: 1.0 + Double(index) * 0.02)).isEmpty)
        }
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.5))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testRejectsPathWithWrongEndpoint() {
        let recognizer = GestureRecognizer(configuration: configuration())
        let wrongPath = Array(pathPoints.dropLast()) + [NormalizedPoint(x: 0.92, y: 0.18)]

        wrongPath.enumerated().forEach { index, point in
            XCTAssertTrue(recognizer.process(touchFrame(point, timestamp: 1.0 + Double(index) * 0.02)).isEmpty)
        }
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.5))

        XCTAssertTrue(gestures.isEmpty)
    }

    private func configuration() -> GestureConfiguration {
        let rule = CustomPathGestureRule(
            name: "Drawn Path",
            isEnabled: true,
            points: pathPoints,
            pointTolerance: 0.08,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(title: "Path", detail: "Matched"))]
        )
        return GestureConfiguration(triggers: [.customPath(id: "drawn", type: .oneFingerDrawnPath, rule: rule)])
    }

    private var pathPoints: [NormalizedPoint] {
        [
            NormalizedPoint(x: 0.20, y: 0.50),
            NormalizedPoint(x: 0.34, y: 0.72),
            NormalizedPoint(x: 0.55, y: 0.74),
            NormalizedPoint(x: 0.74, y: 0.52),
            NormalizedPoint(x: 0.58, y: 0.28),
            NormalizedPoint(x: 0.32, y: 0.30)
        ]
    }

    private func touchFrame(_ point: NormalizedPoint, timestamp: TimeInterval) -> TouchFrame {
        frame(touches: [touch(id: 1, point: point)], timestamp: timestamp)
    }

    private func frame(touches: [TouchPoint], timestamp: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: timestamp, frameNumber: Int(timestamp * 100))
    }

    private func touch(id: Int, point: NormalizedPoint) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: point, pressure: 0.2, size: 0.2)
    }
}
