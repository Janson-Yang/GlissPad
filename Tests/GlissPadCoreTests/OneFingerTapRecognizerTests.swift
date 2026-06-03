@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerTapRecognizerTests: XCTestCase {
    func testSingleTapTriggersOnRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(type: .oneFingerTap, tapCount: 1))

        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.1))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerTap])
    }

    func testTapCancelsWhenSystemClickAppears() {
        let recognizer = GestureRecognizer(configuration: configuration(type: .oneFingerTap, tapCount: 1))

        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.05, clickGeneration: 1)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1, clickGeneration: 1)).isEmpty)
    }

    func testTapCancelsWhenFingerMovesTooFar() {
        let recognizer = GestureRecognizer(configuration: configuration(type: .oneFingerTap, tapCount: 1))

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.4, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.5, timestamp: 1.05)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1)).isEmpty)
    }

    func testDoubleTapTriggersOnSecondTap() {
        let recognizer = GestureRecognizer(configuration: configuration(type: .oneFingerDoubleTap, tapCount: 2))

        performTap(on: recognizer, down: 1.0, up: 1.08)
        XCTAssertEqual(recognizer.process(touchFrame(timestamp: 1.25)).map(\.kind), [])
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.32))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerDoubleTap])
    }

    func testDoubleTapRequiresConfiguredInterval() {
        let recognizer = GestureRecognizer(configuration: configuration(type: .oneFingerDoubleTap, tapCount: 2))

        performTap(on: recognizer, down: 1.0, up: 1.08)
        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.6)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.68)).isEmpty)
    }

    func testDoubleTapRequiresConfiguredMovementToleranceBetweenTaps() {
        let recognizer = GestureRecognizer(configuration: configuration(type: .oneFingerDoubleTap, tapCount: 2))

        performTap(on: recognizer, x: 0.1, down: 1.0, up: 1.08)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.9, timestamp: 1.25)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.32)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.91, timestamp: 1.45)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.52))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerDoubleTap])
    }

    func testDoubleTapIgnoresSystemClickNoise() {
        let recognizer = GestureRecognizer(configuration: configuration(type: .oneFingerDoubleTap, tapCount: 2))

        _ = recognizer.process(touchFrame(timestamp: 1.0))
        _ = recognizer.process(touchFrame(timestamp: 1.04, clickGeneration: 1, hasRecentClick: true))
        _ = recognizer.process(frame(touches: [], timestamp: 1.08, clickGeneration: 1, hasRecentClick: true))
        XCTAssertTrue(recognizer.process(touchFrame(timestamp: 1.25, clickGeneration: 2)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.32, clickGeneration: 2, hasRecentClick: true))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerDoubleTap])
    }

    func testTapRequiresConfiguredRegion() {
        let region = NormalizedRegion(minX: 0.6, maxX: 0.8, minY: 0.4, maxY: 0.6)
        let recognizer = GestureRecognizer(configuration: configuration(type: .oneFingerTap, tapCount: 1, region: region))

        _ = recognizer.process(touchFrame(x: 0.4, timestamp: 1.0))
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.08)).isEmpty)

        _ = recognizer.process(touchFrame(x: 0.7, timestamp: 2.0))
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 2.08)).map(\.kind), [.oneFingerTap])
    }

    private func performTap(on recognizer: GestureRecognizer, x: Double = 0.4, down: TimeInterval, up: TimeInterval) {
        _ = recognizer.process(touchFrame(x: x, timestamp: down))
        _ = recognizer.process(frame(touches: [], timestamp: up))
    }

    private func configuration(
        type: GestureTriggerType,
        tapCount: Int,
        region: NormalizedRegion? = nil
    ) -> GestureConfiguration {
        let rule = TapGestureRule(
            name: type.displayName,
            isEnabled: true,
            tapCount: tapCount,
            cooldownMilliseconds: 650,
            region: region,
            action: ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        )
        return GestureConfiguration(triggers: [.tap(id: type.rawValue, type: type, rule: rule)])
    }

    private func touchFrame(
        x: Double = 0.4,
        timestamp: TimeInterval,
        clickGeneration: UInt64 = 0,
        hasRecentClick: Bool = false
    ) -> TouchFrame {
        frame(
            touches: [touch(x: x)],
            timestamp: timestamp,
            clickGeneration: clickGeneration,
            hasRecentClick: hasRecentClick
        )
    }

    private func frame(
        touches: [TouchPoint],
        timestamp: TimeInterval,
        clickGeneration: UInt64 = 0,
        hasRecentClick: Bool = false
    ) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: timestamp,
            frameNumber: Int(timestamp * 100),
            clickGeneration: clickGeneration,
            hasRecentClick: hasRecentClick
        )
    }

    private func touch(x: Double) -> TouchPoint {
        TouchPoint(id: 1, state: .touching, position: NormalizedPoint(x: x, y: 0.5), pressure: 0.2, size: 0.2)
    }
}
