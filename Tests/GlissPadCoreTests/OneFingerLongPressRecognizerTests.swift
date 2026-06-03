@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerLongPressRecognizerTests: XCTestCase {
    func testTriggersAfterConfiguredHoldDuration() {
        let recognizer = GestureRecognizer(configuration: configuration())

        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.3)).isEmpty)
        let gestures = recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.8))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerLongPress])
    }

    func testDoesNotRepeatWhileFingerStaysDown() {
        let recognizer = GestureRecognizer(configuration: configuration())

        _ = recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.0))
        XCTAssertEqual(recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.8)).map(\.kind), [
            .oneFingerLongPress
        ])
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 2.8)).isEmpty)
    }

    func testCancelsWhenFingerMovesTooFar() {
        let recognizer = GestureRecognizer(configuration: configuration())

        _ = recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.0))

        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, x: 0.6, timestamp: 1.8)).isEmpty)
    }

    func testIgnoresTwoFingerHold() {
        let recognizer = GestureRecognizer(configuration: configuration())

        _ = recognizer.process(fingerFrame(count: 2, x: 0.4, timestamp: 1.0))

        XCTAssertTrue(recognizer.process(fingerFrame(count: 2, x: 0.4, timestamp: 1.8)).isEmpty)
    }

    func testAfterReleaseTimingWaitsForFingerLift() {
        let recognizer = GestureRecognizer(configuration: configuration(triggerTiming: .afterRelease))

        _ = recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.0))
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.8)).isEmpty)
        let gestures = recognizer.process(TouchFrame(touches: [], timestamp: 1.9, frameNumber: 190))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerLongPress])
    }

    func testForceClickRequiresPressureAndSystemClick() {
        let recognizer = GestureRecognizer(configuration: configuration(pressKind: .forceClick))

        _ = recognizer.process(fingerFrame(
            count: 1,
            x: 0.4,
            timestamp: 1.0,
            pressure: TrackpadPressureThreshold.forceClick
        ))
        XCTAssertTrue(recognizer.process(fingerFrame(
            count: 1,
            x: 0.4,
            timestamp: 1.8,
            pressure: TrackpadPressureThreshold.forceClick
        )).isEmpty)
        let clicked = fingerFrame(
            count: 1,
            x: 0.4,
            timestamp: 1.85,
            pressure: TrackpadPressureThreshold.forceClick,
            clickGeneration: 1
        )
        XCTAssertEqual(recognizer.process(clicked).map(\.kind), [.oneFingerLongPress])
    }

    func testRequiresConfiguredRegion() {
        let region = NormalizedRegion(minX: 0.6, maxX: 0.8, minY: 0.4, maxY: 0.6)
        let recognizer = GestureRecognizer(configuration: configuration(region: region))

        _ = recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.0))
        XCTAssertTrue(recognizer.process(fingerFrame(count: 1, x: 0.4, timestamp: 1.8)).isEmpty)

        _ = recognizer.process(fingerFrame(count: 1, x: 0.7, timestamp: 2.0))
        XCTAssertEqual(recognizer.process(fingerFrame(count: 1, x: 0.7, timestamp: 2.81)).map(\.kind), [
            .oneFingerLongPress
        ])
    }

    private func configuration(
        pressKind: HoldPressKind = .touch,
        triggerTiming: HoldTriggerTiming = .whileTouching,
        region: NormalizedRegion? = nil
    ) -> GestureConfiguration {
        let rule = HoldGestureRule(
            name: "Long Press",
            isEnabled: true,
            fingerCount: 1,
            holdMilliseconds: 800,
            maximumMovement: 0.04,
            pressKind: pressKind,
            triggerTiming: triggerTiming,
            minimumPressure: TrackpadPressureThreshold.value(for: pressKind),
            minimumForceMilliseconds: 45,
            cooldownMilliseconds: 650,
            region: region,
            action: ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        )
        return GestureConfiguration(triggers: [
            .hold(id: "long-press", type: .oneFingerLongPress, rule: rule)
        ])
    }

    private func fingerFrame(
        count: Int,
        x: Double,
        timestamp: TimeInterval,
        pressure: Double = TrackpadPressureThreshold.touch,
        clickGeneration: UInt64 = 0
    ) -> TouchFrame {
        let touches = (0..<count).map {
            touch(id: $0 + 1, x: x + Double($0) * 0.04, y: 0.5, pressure: pressure)
        }
        return TouchFrame(
            touches: touches,
            timestamp: timestamp,
            frameNumber: Int(timestamp * 100),
            clickGeneration: clickGeneration
        )
    }

    private func touch(id: Int, x: Double, y: Double, pressure: Double) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: y),
            pressure: pressure,
            size: pressure
        )
    }
}
