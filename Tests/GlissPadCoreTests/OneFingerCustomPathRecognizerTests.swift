@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerCustomPathRecognizerTests: XCTestCase {
    func testTriggersAfterOrderedPointsAndRelease() {
        let recognizer = GestureRecognizer(configuration: configuration())

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.2, y: 0.8, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.5, y: 0.2, timestamp: 1.1)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.8, y: 0.8, timestamp: 1.2)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.3))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerCustomPath])
    }

    func testRequiresIntermediatePointsInOrder() {
        let recognizer = GestureRecognizer(configuration: configuration())

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.2, y: 0.8, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.8, y: 0.8, timestamp: 1.1)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.2))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testTwoFingerContactCancelsUntilRelease() {
        let recognizer = GestureRecognizer(configuration: configuration())

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.2, y: 0.8, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 2, timestamp: 1.1)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.5, y: 0.2, timestamp: 1.2)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.8, y: 0.8, timestamp: 1.3)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.4)).isEmpty)
    }

    private func configuration() -> GestureConfiguration {
        let rule = CustomPathGestureRule(
            name: "Path",
            isEnabled: true,
            points: [
                NormalizedPoint(x: 0.2, y: 0.8),
                NormalizedPoint(x: 0.5, y: 0.2),
                NormalizedPoint(x: 0.8, y: 0.8)
            ],
            pointTolerance: 0.06,
            cooldownMilliseconds: 650,
            actions: [.script(ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript))]
        )
        return GestureConfiguration(triggers: [.customPath(id: "path", type: .oneFingerCustomPath, rule: rule)])
    }

    private func touchFrame(x: Double, y: Double, timestamp: TimeInterval) -> TouchFrame {
        frame(touches: [touch(id: 1, x: x, y: y)], timestamp: timestamp)
    }

    private func fingerFrame(count: Int, timestamp: TimeInterval) -> TouchFrame {
        let touches = (0..<count).map { touch(id: $0 + 1, x: 0.2 + Double($0) * 0.03, y: 0.8) }
        return frame(touches: touches, timestamp: timestamp)
    }

    private func frame(touches: [TouchPoint], timestamp: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: timestamp, frameNumber: Int(timestamp * 100))
    }

    private func touch(id: Int, x: Double, y: Double) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: 0.2, size: 0.2)
    }
}
