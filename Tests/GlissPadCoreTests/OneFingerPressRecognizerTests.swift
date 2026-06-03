@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerPressRecognizerTests: XCTestCase {
    func testClickTriggersOnlyAfterSystemClickAndRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(pressKind: .click))

        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1)).isEmpty)

        XCTAssertTrue(recognizer.process(touchFrame(
            timestamp: 2.0,
            pressure: TrackpadPressureThreshold.click
        )).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(
            timestamp: 2.05,
            pressure: TrackpadPressureThreshold.clickSustain,
            clickGeneration: 1
        )).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 2.1, clickGeneration: 1))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerPress])
    }

    func testForceClickRequiresPressureAndSystemClick() {
        let recognizer = GestureRecognizer(configuration: configuration(pressKind: .forceClick))

        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.0, pressure: 0.9)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.06, pressure: 0.9)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1)).isEmpty)

        XCTAssertTrue(recognizer.process(touchFrame(
            timestamp: 2.0,
            pressure: TrackpadPressureThreshold.forceClick
        )).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(
            timestamp: 2.06,
            pressure: TrackpadPressureThreshold.forceClick,
            clickGeneration: 1
        )).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 2.1, clickGeneration: 1))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerPress])
    }

    func testForceClickIgnoresClickBelowPressure() {
        let recognizer = GestureRecognizer(configuration: configuration(pressKind: .forceClick))

        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.0, pressure: 0.4)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.06, pressure: 0.4, clickGeneration: 1)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.1, clickGeneration: 1))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testMovementCancelsPress() {
        let recognizer = GestureRecognizer(configuration: configuration(pressKind: .click))

        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.58, timestamp: 1.05, clickGeneration: 1)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.1, clickGeneration: 1))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testTwoFingerContactCancelsUntilRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(pressKind: .click))

        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 2, timestamp: 1.05, clickGeneration: 1)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.08, clickGeneration: 1)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1, clickGeneration: 1)).isEmpty)
    }

    private func configuration(pressKind: OneFingerPressKind) -> GestureConfiguration {
        let rule = OneFingerPressGestureRule(
            name: "Press",
            isEnabled: true,
            pressKind: pressKind,
            minimumPressure: TrackpadPressureThreshold.value(for: pressKind),
            minimumForceMilliseconds: 45,
            maximumMovement: 0.04,
            cooldownMilliseconds: 650,
            actions: [.script(ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript))]
        )
        return GestureConfiguration(triggers: [.oneFingerPress(id: "press", type: .oneFingerPress, rule: rule)])
    }

    private func touchFrame(
        x: Double = 0.5,
        y: Double = 0.5,
        timestamp: TimeInterval,
        pressure: Double = TrackpadPressureThreshold.touch,
        clickGeneration: UInt64 = 0
    ) -> TouchFrame {
        frame(
            touches: [touch(id: 1, x: x, y: y, pressure: pressure)],
            timestamp: timestamp,
            clickGeneration: clickGeneration
        )
    }

    private func fingerFrame(count: Int, timestamp: TimeInterval, clickGeneration: UInt64) -> TouchFrame {
        let touches = (0..<count).map { touch(id: $0 + 1, x: 0.5 + Double($0) * 0.02, y: 0.5) }
        return frame(touches: touches, timestamp: timestamp, clickGeneration: clickGeneration)
    }

    private func frame(
        touches: [TouchPoint],
        timestamp: TimeInterval,
        clickGeneration: UInt64 = 0
    ) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: timestamp, frameNumber: Int(timestamp * 100), clickGeneration: clickGeneration)
    }

    private func touch(
        id: Int,
        x: Double,
        y: Double,
        pressure: Double = TrackpadPressureThreshold.touch
    ) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: pressure, size: pressure)
    }
}
