@testable import GlissPadCore
import Foundation
import XCTest

final class ReleaseGestureRecognizerTests: XCTestCase {
    func testTriggersAfterConfiguredFingerCountReleases() {
        let recognizer = GestureRecognizer(configuration: configuration(.exact(2)))

        XCTAssertTrue(recognizer.process(fingerFrame(count: 2, timestamp: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.1))

        XCTAssertEqual(gestures.map(\.kind), [.releaseLastFinger])
        XCTAssertEqual(gestures.first?.action.script, DefaultScripts.placeholderAppleScript)
    }

    func testIgnoresWrongPreviousFingerCount() {
        let recognizer = GestureRecognizer(configuration: configuration(.exact(2)))

        XCTAssertTrue(recognizer.process(fingerFrame(count: 3, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1)).isEmpty)
    }

    func testAnyAcceptsFiveFingers() {
        let recognizer = GestureRecognizer(configuration: configuration(.any))

        XCTAssertTrue(recognizer.process(fingerFrame(count: 5, timestamp: 1.0)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.1)).map(\.kind), [
            .releaseLastFinger
        ])
    }

    func testAllowsStaggeredReleaseWithinTolerance() {
        let recognizer = GestureRecognizer(configuration: configuration(.exact(3), releaseTolerance: 200))

        XCTAssertTrue(recognizer.process(fingerFrame(count: 3, timestamp: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 2, timestamp: 1.05)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, timestamp: 1.18)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.30))

        XCTAssertEqual(gestures.map(\.kind), [.releaseLastFinger])
    }

    func testStaggeredReleasePastToleranceDoesNotUseOriginalCount() {
        let recognizer = GestureRecognizer(configuration: configuration(.exact(3), releaseTolerance: 100))

        XCTAssertTrue(recognizer.process(fingerFrame(count: 3, timestamp: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 2, timestamp: 1.05)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, timestamp: 1.30)).isEmpty)

        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.35)).isEmpty)
    }

    func testRespectsCooldown() {
        let recognizer = GestureRecognizer(configuration: configuration(.exact(1), cooldown: 650))

        _ = recognizer.process(fingerFrame(count: 1, timestamp: 1.0))
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.1)).map(\.kind), [.releaseLastFinger])
        _ = recognizer.process(fingerFrame(count: 1, timestamp: 1.2))
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.3)).isEmpty)
        _ = recognizer.process(fingerFrame(count: 1, timestamp: 1.8))
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.9)).map(\.kind), [.releaseLastFinger])
    }

    private func configuration(
        _ previousFingerCount: ReleaseFingerCount,
        releaseTolerance: Int = 200,
        cooldown: Int = 650
    ) -> GestureConfiguration {
        let rule = ReleaseGestureRule(
            name: "Release Last Finger",
            isEnabled: true,
            previousFingerCount: previousFingerCount,
            releaseToleranceMilliseconds: releaseTolerance,
            cooldownMilliseconds: cooldown,
            action: ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        )
        return GestureConfiguration(triggers: [
            .release(id: "release", type: .releaseLastFinger, rule: rule)
        ])
    }

    private func fingerFrame(count: Int, timestamp: TimeInterval) -> TouchFrame {
        let touches = (0..<count).map {
            touch(id: $0 + 1, x: 0.2 + Double($0) * 0.08, y: 0.5)
        }
        return frame(touches: touches, timestamp: timestamp)
    }

    private func frame(touches: [TouchPoint], timestamp: TimeInterval) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: timestamp,
            frameNumber: Int(timestamp * 100)
        )
    }

    private func touch(id: Int, x: Double, y: Double) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: y),
            pressure: 0.2,
            size: 0.2
        )
    }
}
