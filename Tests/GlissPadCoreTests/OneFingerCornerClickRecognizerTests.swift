@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerCornerClickRecognizerTests: XCTestCase {
    func testTapTriggersWithoutSystemClick() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .tap))

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.1))

        XCTAssertEqual(gestures.map(\.kind), [.oneFingerCornerClick])
    }

    func testTapIgnoresRealClick() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .tap))

        _ = recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.0))
        _ = recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.05, clickGeneration: 1))
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.1, clickGeneration: 1))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testClickAcceptsSystemClickEvent() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .click))

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1)).isEmpty)

        XCTAssertTrue(recognizer.process(touchFrame(
            x: 0.9,
            y: 0.85,
            timestamp: 2.0,
            pressure: TrackpadPressureThreshold.click
        )).isEmpty)
        let clicked = touchFrame(
            x: 0.9,
            y: 0.85,
            timestamp: 2.05,
            pressure: TrackpadPressureThreshold.clickSustain,
            clickGeneration: 1
        )
        XCTAssertTrue(recognizer.process(clicked).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 2.1, clickGeneration: 1)).map(\.kind), [
            .oneFingerCornerClick
        ])
    }

    func testClickCanUsePressureWhenSystemClickEventIsMissing() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .click))

        XCTAssertTrue(recognizer.process(touchFrame(
            x: 0.9,
            y: 0.85,
            timestamp: 1.0,
            pressure: TrackpadPressureThreshold.click
        )).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(
            x: 0.9,
            y: 0.85,
            timestamp: 1.05,
            pressure: TrackpadPressureThreshold.clickSustain
        )).isEmpty)

        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.08)).map(\.kind), [
            .oneFingerCornerClick
        ])
    }

    func testClickAcceptsRecentSystemClickOnRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .click))

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.0)).isEmpty)

        XCTAssertEqual(
            recognizer.process(frame(touches: [], timestamp: 1.05, hasRecentClick: true)).map(\.kind),
            [.oneFingerCornerClick]
        )
    }

    func testForceClickAcceptsPressureWithSystemClickEvent() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .forceClick))

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.0, pressure: 0.9)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.06, pressure: 0.9)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1)).isEmpty)

        XCTAssertTrue(recognizer.process(touchFrame(
            x: 0.9,
            y: 0.85,
            timestamp: 2.0,
            pressure: TrackpadPressureThreshold.forceClick
        )).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(
            x: 0.9,
            y: 0.85,
            timestamp: 2.06,
            pressure: TrackpadPressureThreshold.forceClick,
            clickGeneration: 1
        )).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 2.1, clickGeneration: 1)).map(\.kind), [
            .oneFingerCornerClick
        ])
    }

    func testForceClickCanUsePressureWhenSystemClickEventIsMissing() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .forceClick))

        XCTAssertTrue(recognizer.process(touchFrame(
            x: 0.9,
            y: 0.85,
            timestamp: 1.0,
            pressure: TrackpadPressureThreshold.forceClick
        )).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(
            x: 0.9,
            y: 0.85,
            timestamp: 1.06,
            pressure: TrackpadPressureThreshold.forceClickSustain
        )).isEmpty)

        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.1)).map(\.kind), [
            .oneFingerCornerClick
        ])
    }

    func testOutsideRegionDoesNotTrigger() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .tap))

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.5, y: 0.5, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1)).isEmpty)
    }

    func testTwoFingerContactCancelsUntilRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(clickKind: .tap))

        XCTAssertTrue(recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(fingerFrame(count: 2, timestamp: 1.05)).isEmpty)
        XCTAssertTrue(recognizer.process(touchFrame(x: 0.9, y: 0.85, timestamp: 1.08)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1)).isEmpty)
    }

    private func configuration(clickKind: CornerClickKind) -> GestureConfiguration {
        let rule = CornerClickGestureRule(
            name: "Corner Click",
            isEnabled: true,
            corner: .upperRight,
            clickKind: clickKind,
            cooldownMilliseconds: 650,
            action: ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        )
        return GestureConfiguration(triggers: [
            .cornerClick(id: "corner", type: .oneFingerCornerClick, rule: rule)
        ])
    }

    private func touchFrame(
        x: Double,
        y: Double,
        timestamp: TimeInterval,
        pressure: Double = TrackpadPressureThreshold.touch,
        clickGeneration: UInt64 = 0
    ) -> TouchFrame {
        frame(touches: [touch(id: 1, x: x, y: y, pressure: pressure)], timestamp: timestamp, clickGeneration: clickGeneration)
    }

    private func fingerFrame(count: Int, timestamp: TimeInterval) -> TouchFrame {
        let touches = (0..<count).map { touch(id: $0 + 1, x: 0.9 - Double($0) * 0.04, y: 0.85) }
        return frame(touches: touches, timestamp: timestamp)
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

    private func touch(
        id: Int,
        x: Double,
        y: Double,
        pressure: Double = TrackpadPressureThreshold.touch
    ) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: pressure, size: pressure)
    }
}
