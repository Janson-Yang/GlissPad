@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerGestureRecognizerTests: XCTestCase {
    func testTriggersWhenFirstFingerTouchesSurface() {
        let recognizer = GestureRecognizer(configuration: configuration())

        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.0)).isEmpty)
        let gestures = recognizer.process(fingerFrame(count: 1, timestamp: 1.1))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerTouchStart])
        XCTAssertEqual(gestures.first?.name, "Touch Start")
    }

    func testDoesNotRepeatWhileFingerStaysDown() {
        let recognizer = GestureRecognizer(configuration: configuration())

        XCTAssertEqual(recognizer.process(fingerFrame(count: 1, timestamp: 1.0)).map(\.kind), [
            .oneFingerTouchStart
        ])
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, timestamp: 1.1)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, timestamp: 1.2)).isEmpty)
    }

    func testIgnoresTwoFingerStart() {
        let recognizer = GestureRecognizer(configuration: configuration())

        XCTAssertTrue(recognizer.process(fingerFrame(count: 2, timestamp: 1.0)).isEmpty)
    }

    func testRequiresConfiguredRegion() {
        let region = NormalizedRegion(minX: 0.6, maxX: 0.8, minY: 0.4, maxY: 0.6)
        let recognizer = GestureRecognizer(configuration: configuration(region: region))

        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, x: 0.2, timestamp: 1.0)).isEmpty)
        _ = recognizer.process(frame(touches: [], timestamp: 1.1))
        XCTAssertEqual(recognizer.process(fingerFrame(count: 1, x: 0.7, timestamp: 1.8)).map(\.kind), [
            .oneFingerTouchStart
        ])
    }

    func testRespectsCooldown() {
        let recognizer = GestureRecognizer(configuration: configuration(cooldown: 650))

        XCTAssertEqual(recognizer.process(fingerFrame(count: 1, timestamp: 1.0)).map(\.kind), [
            .oneFingerTouchStart
        ])
        _ = recognizer.process(frame(touches: [], timestamp: 1.1))
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, timestamp: 1.2)).isEmpty)
        _ = recognizer.process(frame(touches: [], timestamp: 1.7))
        XCTAssertEqual(recognizer.process(fingerFrame(count: 1, timestamp: 1.8)).map(\.kind), [
            .oneFingerTouchStart
        ])
    }

    private func configuration(cooldown: Int = 650, region: NormalizedRegion? = nil) -> GestureConfiguration {
        let rule = OneFingerGestureRule(
            name: "Touch Start",
            isEnabled: true,
            cooldownMilliseconds: cooldown,
            region: region,
            action: ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        )
        return GestureConfiguration(triggers: [
            .oneFinger(id: "touch-start", type: .oneFingerTouchStart, rule: rule)
        ])
    }

    private func fingerFrame(count: Int, x: Double = 0.2, timestamp: TimeInterval) -> TouchFrame {
        let touches = (0..<count).map {
            touch(id: $0 + 1, x: x + Double($0) * 0.08, y: 0.5)
        }
        return frame(touches: touches, timestamp: timestamp)
    }

    private func frame(touches: [TouchPoint], timestamp: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: timestamp, frameNumber: Int(timestamp * 100))
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
