@testable import GlissPadCore
import Foundation
import XCTest

final class GestureRecognizerTests: XCTestCase {
    private let forcePressure = TrackpadPressureThreshold.forceClick

    func testThreeFingerForcePressTriggersOnlyAfterAllFingersRelease() {
        let recognizer = legacyDefaultRecognizer()
        let pressed = threeFingerFrame(timestamp: 1.0, pressure: forcePressure, clickGeneration: 10)

        XCTAssertTrue(recognizer.process(pressed).isEmpty)
        XCTAssertTrue(recognizer.process(frame(
            touches: pressed.touches,
            timestamp: 1.09,
            clickGeneration: 11
        )).isEmpty)
        XCTAssertTrue(recognizer.process(frame(
            touches: [pressed.touches[0]],
            timestamp: 1.10,
            clickGeneration: 11
        )).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.12, clickGeneration: 11))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerForcePress])
        XCTAssertEqual(gestures.first?.action.language, .appleScript)
    }

    func testThreeFingerForcePressRespectsCooldownAfterRelease() {
        let recognizer = legacyDefaultRecognizer()
        armAndReleaseThreeFingerPress(recognizer, start: 1.0)

        _ = recognizer.process(threeFingerFrame(timestamp: 1.3, pressure: forcePressure, clickGeneration: 20))
        _ = recognizer.process(threeFingerFrame(timestamp: 1.39, pressure: forcePressure, clickGeneration: 21))
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.42, clickGeneration: 21)).isEmpty)

        _ = recognizer.process(threeFingerFrame(timestamp: 1.8, pressure: forcePressure, clickGeneration: 30))
        _ = recognizer.process(threeFingerFrame(timestamp: 1.89, pressure: forcePressure, clickGeneration: 31))
        XCTAssertEqual(
            recognizer.process(frame(touches: [], timestamp: 1.92, clickGeneration: 31)).map(\.kind),
            [.threeFingerForcePress]
        )
    }

    func testUpperRightForcePressRequiresConfiguredRegion() {
        let recognizer = legacyDefaultRecognizer()
        let outside = frame(touches: [touch(id: 1, x: 0.70, y: 0.96, pressure: forcePressure)], timestamp: 1.0)
        let inside = frame(touches: [touch(id: 1, x: 0.90, y: 0.86, pressure: forcePressure)], timestamp: 2.0)

        XCTAssertTrue(recognizer.process(outside).isEmpty)
        XCTAssertTrue(recognizer.process(inside).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: inside.touches, timestamp: 2.06, clickGeneration: 1)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 2.1, clickGeneration: 1)).map(\.kind), [
            .upperRightForcePress
        ])
    }

    func testUpperLeftForcePressRunsCommandScript() {
        let recognizer = legacyDefaultRecognizer()
        let outside = frame(touches: [touch(id: 1, x: 0.30, y: 0.86, pressure: forcePressure)], timestamp: 1.0)
        let inside = frame(touches: [touch(id: 1, x: 0.10, y: 0.86, pressure: forcePressure)], timestamp: 2.0)

        XCTAssertTrue(recognizer.process(outside).isEmpty)
        XCTAssertTrue(recognizer.process(inside).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: inside.touches, timestamp: 2.06, clickGeneration: 1)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 2.1, clickGeneration: 1))

        XCTAssertEqual(gestures.map(\.kind), [.upperLeftForcePress])
        XCTAssertEqual(gestures.first?.action.script, DefaultScripts.placeholderAppleScript)
    }

    func testCornerForcePressRequiresSystemClick() {
        let recognizer = legacyDefaultRecognizer()
        let leftCorner = frame(touches: [touch(id: 1, x: 0.10, y: 0.86, pressure: forcePressure)], timestamp: 1.0)
        let rightCorner = frame(touches: [touch(id: 1, x: 0.90, y: 0.86, pressure: forcePressure)], timestamp: 2.0)

        XCTAssertTrue(recognizer.process(leftCorner).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: leftCorner.touches, timestamp: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.10)).isEmpty)
        XCTAssertTrue(recognizer.process(rightCorner).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: rightCorner.touches, timestamp: 2.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 2.10)).isEmpty)
    }

    func testLeftEdgeTwoFingerSwipeTriggersAfterQuarterWidthTravel() {
        let recognizer = legacyDefaultRecognizer()
        let start = twoFingerFrame(timestamp: 1.0, x: 0.06, y: 0.50)
        let moved = twoFingerFrame(timestamp: 1.2, x: 0.33, y: 0.50)

        XCTAssertTrue(recognizer.process(start).isEmpty)
        XCTAssertTrue(recognizer.process(moved).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.25))

        XCTAssertEqual(gestures.map(\.kind), [.leftEdgeTwoFingerSwipe])
        XCTAssertEqual(gestures.first?.action.script, DefaultScripts.placeholderAppleScript)
    }

    func testLeftEdgeTwoFingerSwipeRequiresLeftEdgeStart() {
        let recognizer = legacyDefaultRecognizer()
        let start = twoFingerFrame(timestamp: 1.0, x: 0.22, y: 0.50)
        let moved = twoFingerFrame(timestamp: 1.2, x: 0.49, y: 0.50)

        XCTAssertTrue(recognizer.process(start).isEmpty)
        XCTAssertTrue(recognizer.process(moved).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.25)).isEmpty)
    }

    func testLeftEdgeTwoFingerSwipeRequiresMinimumTravel() {
        let recognizer = legacyDefaultRecognizer()
        let start = twoFingerFrame(timestamp: 1.0, x: 0.06, y: 0.50)
        let moved = twoFingerFrame(timestamp: 1.2, x: 0.25, y: 0.50)

        XCTAssertTrue(recognizer.process(start).isEmpty)
        XCTAssertTrue(recognizer.process(moved).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.25)).isEmpty)
    }

    func testLeftEdgeTwoFingerSwipeAllowsVerticalDrift() {
        let recognizer = legacyDefaultRecognizer()
        let start = twoFingerFrame(timestamp: 1.0, x: 0.06, y: 0.50)
        let moved = twoFingerFrame(timestamp: 1.2, x: 0.33, y: 0.72)

        XCTAssertTrue(recognizer.process(start).isEmpty)
        XCTAssertTrue(recognizer.process(moved).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.25)).map(\.kind), [
            .leftEdgeTwoFingerSwipe
        ])
    }

    func testTwoFingerHoldTriggersAfterThreeSeconds() {
        let recognizer = legacyDefaultRecognizer()
        let hold = twoFingerFrame(timestamp: 1.0, x: 0.50, y: 0.50)

        XCTAssertTrue(recognizer.process(hold).isEmpty)
        XCTAssertTrue(recognizer.process(twoFingerFrame(timestamp: 3.99, x: 0.50, y: 0.50)).isEmpty)
        let gestures = recognizer.process(twoFingerFrame(timestamp: 4.0, x: 0.50, y: 0.50))

        XCTAssertEqual(gestures.map(\.kind), [.twoFingerHold])
        XCTAssertEqual(gestures.first?.action.script, DefaultScripts.placeholderAppleScript)
        XCTAssertTrue(recognizer.process(twoFingerFrame(timestamp: 4.2, x: 0.50, y: 0.50)).isEmpty)
    }

    func testTwoFingerHoldCancelsWhenCentroidMoves() {
        let recognizer = legacyDefaultRecognizer()

        XCTAssertTrue(recognizer.process(twoFingerFrame(timestamp: 1.0, x: 0.50, y: 0.50)).isEmpty)
        XCTAssertTrue(recognizer.process(twoFingerFrame(timestamp: 2.0, x: 0.60, y: 0.50)).isEmpty)
        XCTAssertTrue(recognizer.process(twoFingerFrame(timestamp: 4.1, x: 0.60, y: 0.50)).isEmpty)
    }

    func testTwoFingerHoldRequiresTwoFingers() {
        let recognizer = legacyDefaultRecognizer()
        let oneFinger = frame(touches: [touch(id: 1, x: 0.50, y: 0.50, pressure: 0.2)], timestamp: 1.0)

        XCTAssertTrue(recognizer.process(oneFinger).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: oneFinger.touches, timestamp: 4.1)).isEmpty)
    }

    func testTwoFingerHoldRequiresConfiguredRegion() {
        var configuration = legacyDefaultConfiguration()
        configuration.twoFingerHold.region = NormalizedRegion(minX: 0.40, maxX: 0.80, minY: 0.40, maxY: 0.80)
        let recognizer = GestureRecognizer(configuration: configuration)

        XCTAssertTrue(recognizer.process(twoFingerFrame(timestamp: 1.0, x: 0.20, y: 0.50)).isEmpty)
        XCTAssertTrue(recognizer.process(twoFingerFrame(timestamp: 4.1, x: 0.20, y: 0.50)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 4.2)).isEmpty)
        XCTAssertTrue(recognizer.process(twoFingerFrame(timestamp: 5.0, x: 0.55, y: 0.50)).isEmpty)
        XCTAssertEqual(recognizer.process(twoFingerFrame(timestamp: 8.0, x: 0.55, y: 0.50)).map(\.kind), [
            .twoFingerHold
        ])
    }

    func testPressBelowPressureThresholdDoesNotTrigger() {
        let recognizer = legacyDefaultRecognizer()
        let weakPress = threeFingerFrame(timestamp: 1.0, pressure: 0.2, clickGeneration: 10)

        XCTAssertTrue(recognizer.process(weakPress).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: weakPress.touches, timestamp: 1.2, clickGeneration: 11)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.3, clickGeneration: 11)).isEmpty)
    }

    func testSingleFramePressureSpikeDoesNotTrigger() {
        let recognizer = legacyDefaultRecognizer()
        let spike = threeFingerFrame(timestamp: 1.0, pressure: forcePressure, clickGeneration: 10)
        let relaxed = threeFingerFrame(timestamp: 1.06, pressure: 0.2, clickGeneration: 11)

        XCTAssertTrue(recognizer.process(spike).isEmpty)
        XCTAssertTrue(recognizer.process(relaxed).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.1, clickGeneration: 11)).isEmpty)
    }

    func testForcePressAllowsSustainedPressureAfterActivation() {
        let recognizer = legacyDefaultRecognizer()

        XCTAssertTrue(recognizer.process(threeFingerFrame(
            timestamp: 1.0,
            pressure: TrackpadPressureThreshold.forceClick,
            clickGeneration: 10
        )).isEmpty)
        XCTAssertTrue(recognizer.process(threeFingerFrame(
            timestamp: 1.09,
            pressure: TrackpadPressureThreshold.forceClickSustain,
            clickGeneration: 11
        )).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.12, clickGeneration: 11)).map(\.kind), [
            .threeFingerForcePress
        ])
    }

    func testForcePressCancelsBelowSustainedPressure() {
        let recognizer = legacyDefaultRecognizer()

        XCTAssertTrue(recognizer.process(threeFingerFrame(
            timestamp: 1.0,
            pressure: TrackpadPressureThreshold.forceClick,
            clickGeneration: 10
        )).isEmpty)
        XCTAssertTrue(recognizer.process(threeFingerFrame(
            timestamp: 1.09,
            pressure: TrackpadPressureThreshold.forceClickSustain - 0.1,
            clickGeneration: 11
        )).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.12, clickGeneration: 11)).isEmpty)
    }

    func testThreeFingerForcePressCancelsWhenTouchCentroidMoves() {
        let recognizer = legacyDefaultRecognizer()
        let start = threeFingerFrame(timestamp: 1.0, pressure: forcePressure, clickGeneration: 10)
        let movedTouches = start.touches.map {
            touch(id: $0.id, x: $0.position.x + 0.12, y: $0.position.y, pressure: forcePressure)
        }

        XCTAssertTrue(recognizer.process(start).isEmpty)
        XCTAssertTrue(recognizer.process(frame(
            touches: movedTouches,
            timestamp: 1.09,
            clickGeneration: 11
        )).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.12, clickGeneration: 11)).isEmpty)
    }

    func testThreeFingerForcePressRequiresSystemClick() {
        var configuration = legacyDefaultConfiguration()
        configuration.threeFingerForcePress.requiresClick = true
        let recognizer = GestureRecognizer(configuration: configuration)
        let pressed = threeFingerFrame(timestamp: 1.0, pressure: forcePressure, clickGeneration: 10)

        XCTAssertTrue(recognizer.process(pressed).isEmpty)
        XCTAssertTrue(recognizer.process(threeFingerFrame(timestamp: 1.09, pressure: forcePressure, clickGeneration: 10)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], timestamp: 1.12, clickGeneration: 10)).isEmpty)
    }

    func testRecentSystemClickCanArmForcePress() {
        let recognizer = legacyDefaultRecognizer()
        let pressed = threeFingerFrame(
            timestamp: 1.0,
            pressure: forcePressure,
            clickGeneration: 10,
            hasRecentClick: true
        )

        XCTAssertTrue(recognizer.process(pressed).isEmpty)
        XCTAssertTrue(recognizer.process(threeFingerFrame(timestamp: 1.09, pressure: forcePressure, clickGeneration: 10)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.12, clickGeneration: 10)).map(\.kind), [
            .threeFingerForcePress
        ])
    }

}
