@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerCircleRecognizerTests: XCTestCase {
    func testClockwiseCircleTriggersAfterRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(direction: .clockwise))

        processCircle(on: recognizer, direction: .clockwise)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.5))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerCircle])
        XCTAssertEqual(gestures.first?.name, "Circle")
    }

    func testCounterclockwiseCircleTriggersAfterRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(direction: .counterclockwise))

        processCircle(on: recognizer, direction: .counterclockwise)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.5))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerCircle])
    }

    func testWrongDirectionDoesNotTrigger() {
        let recognizer = GestureRecognizer(configuration: configuration(direction: .clockwise))

        processCircle(on: recognizer, direction: .counterclockwise)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.5))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testIncompleteArcDoesNotTrigger() {
        let recognizer = GestureRecognizer(configuration: configuration(direction: .clockwise))

        processArc(on: recognizer, radians: -.pi, sampleCount: 8)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.5))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testTwoFingerContactCancelsCircle() {
        let recognizer = GestureRecognizer(configuration: configuration(direction: .clockwise))

        processArc(on: recognizer, radians: -.pi, sampleCount: 8)
        _ = recognizer.process(fingerFrame(count: 2, timestamp: 1.3))
        processArc(on: recognizer, radians: -.pi, sampleCount: 8, timestampOffset: 1.4)
        let gestures = recognizer.process(frame(touches: [], timestamp: 2.0))

        XCTAssertTrue(gestures.isEmpty)
    }

    private func configuration(direction: CircleDirection) -> GestureConfiguration {
        let rule = CircleGestureRule(
            name: "Circle",
            isEnabled: true,
            direction: direction,
            cooldownMilliseconds: 650,
            action: ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        )
        return GestureConfiguration(triggers: [
            .circle(id: "circle", type: .oneFingerCircle, rule: rule)
        ])
    }

    private func processCircle(on recognizer: GestureRecognizer, direction: CircleDirection) {
        let radians = direction == .clockwise ? -Double.pi * 2 : Double.pi * 2
        processArc(on: recognizer, radians: radians, sampleCount: 20)
    }

    private func processArc(
        on recognizer: GestureRecognizer,
        radians: Double,
        sampleCount: Int,
        timestampOffset: TimeInterval = 1.0
    ) {
        for index in 0...sampleCount {
            let progress = Double(index) / Double(sampleCount)
            _ = recognizer.process(pointFrame(angle: radians * progress, timestamp: timestampOffset + progress * 0.4))
        }
    }

    private func pointFrame(angle: Double, timestamp: TimeInterval) -> TouchFrame {
        let center = NormalizedPoint(x: 0.5, y: 0.5)
        let radius = 0.15
        let point = NormalizedPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        return frame(touches: [touch(id: 1, point: point)], timestamp: timestamp)
    }

    private func fingerFrame(count: Int, timestamp: TimeInterval) -> TouchFrame {
        let touches = (0..<count).map {
            touch(id: $0 + 1, point: NormalizedPoint(x: 0.3 + Double($0) * 0.1, y: 0.5))
        }
        return frame(touches: touches, timestamp: timestamp)
    }

    private func frame(touches: [TouchPoint], timestamp: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: timestamp, frameNumber: Int(timestamp * 100))
    }

    private func touch(id: Int, point: NormalizedPoint) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: point, pressure: 0.2, size: 0.2)
    }
}
