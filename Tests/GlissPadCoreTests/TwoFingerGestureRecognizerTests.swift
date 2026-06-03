@testable import GlissPadCore
import Foundation
import XCTest

final class TwoFingerGestureRecognizerTests: XCTestCase {
    func testTwoFingerTouchStartTriggersWhenSecondFingerTouches() {
        let recognizer = GestureRecognizer(configuration: configuration(
            .touchStart(id: "start", type: .twoFingerTouchStart, rule: touchStartRule())
        ))

        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.4)], timestamp: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: twoTouches(), timestamp: 1.1))

        XCTAssertEqual(gestures.map(\.kind), [.twoFingerTouchStart])
    }

    func testTwoFingerClickLongPressTriggersFromPressureOnly() {
        let recognizer = GestureRecognizer(configuration: configuration(
            .hold(id: "hold", type: .twoFingerHold, rule: holdRule(pressKind: .click))
        ))

        XCTAssertTrue(recognizer.process(frame(touches: twoTouches(pressure: 1.0), timestamp: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: twoTouches(pressure: 0.8), timestamp: 1.11))

        XCTAssertEqual(gestures.map(\.kind), [.twoFingerHold])
    }

    func testTwoFingerTapTriggersOnTwoFingerRelease() {
        let recognizer = GestureRecognizer(configuration: configuration(
            .tap(id: "tap", type: .twoFingerTap, rule: tapRule(pressKind: .touch))
        ))

        XCTAssertTrue(recognizer.process(frame(touches: twoTouches(), timestamp: 1.0)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: [], timestamp: 1.1)).map(\.kind), [.twoFingerTap])
    }

    func testTipTapTriggersWhenSecondFingerReleasesFirst() {
        let recognizer = GestureRecognizer(configuration: configuration(
            .tipTap(id: "tip", type: .tipTap, rule: tipTapRule())
        ))

        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.4)], timestamp: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: twoTouches(), timestamp: 1.05)).isEmpty)
        let gestures = recognizer.process(frame(touches: [touch(id: 1, x: 0.4)], timestamp: 1.12))

        XCTAssertEqual(gestures.map(\.kind), [.tipTap])
    }

    func testPinchAndRotateGesturesTriggerAfterRelease() {
        XCTAssertEqual(transformResult(.pinchIn, movedTouches: twoTouches(x1: 0.46, x2: 0.54)), .pinchIn)
        XCTAssertEqual(transformResult(.pinchOut, movedTouches: twoTouches(x1: 0.35, x2: 0.65)), .pinchOut)
        XCTAssertEqual(transformResult(.rotateLeft, movedTouches: rotateTouches(left: true)), .rotateLeft)
        XCTAssertEqual(transformResult(.rotateRight, movedTouches: rotateTouches(left: false)), .rotateRight)
    }

    func testRotateUsesStableTouchIdentityWhenInputOrderChanges() {
        let moved = rotateTouches(left: true).reversed()

        XCTAssertEqual(transformResult(.rotateLeft, movedTouches: Array(moved)), .rotateLeft)
    }

    func testRotateTriggersAtDefaultSensitivity() {
        XCTAssertEqual(transformResult(.rotateLeft, movedTouches: rotatedTouches(degrees: 9)), .rotateLeft)
        XCTAssertEqual(transformResult(.rotateRight, movedTouches: rotatedTouches(degrees: -9)), .rotateRight)
    }

    func testRotateIgnoresSubthresholdMotion() {
        XCTAssertNil(transformResult(.rotateLeft, movedTouches: rotatedTouches(degrees: 4)))
        XCTAssertNil(transformResult(.rotateRight, movedTouches: rotatedTouches(degrees: -4)))
    }

    func testRotateTriggersWhenFingersLiftOneAtATimeAfterAnimationPath() {
        XCTAssertEqual(transformResult(.rotateLeft, frames: leftRotationAnimationFrames()), .rotateLeft)
        XCTAssertEqual(transformResult(.rotateRight, frames: rightRotationAnimationFrames()), .rotateRight)
    }

    func testRotateAllowsOneFingerPivotMotion() {
        XCTAssertEqual(transformResult(.rotateLeft, movedTouches: pivotRotationTouches(degrees: 24)), .rotateLeft)
        XCTAssertEqual(transformResult(.rotateRight, movedTouches: pivotRotationTouches(degrees: -24)), .rotateRight)
    }

    func testRotateIgnoresTwoFingerSwipeDrift() {
        XCTAssertNil(transformResult(.rotateLeft, movedTouches: swipeDriftTouches(left: true)))
        XCTAssertNil(transformResult(.rotateRight, movedTouches: swipeDriftTouches(left: false)))
    }

    func testRotateIgnoresPinchWithAngleNoise() {
        XCTAssertNil(transformResult(.rotateLeft, movedTouches: noisyPinchTouches(left: true)))
        XCTAssertNil(transformResult(.rotateRight, movedTouches: noisyPinchTouches(left: false)))
    }

    private func transformResult(_ type: GestureTriggerType, movedTouches: [TouchPoint]) -> GestureTriggerType? {
        transformResult(type, frames: [twoTouches(), movedTouches, []])
    }

    private func transformResult(_ type: GestureTriggerType, frames: [[TouchPoint]]) -> GestureTriggerType? {
        let recognizer = GestureRecognizer(configuration: configuration(
            .transform(id: type.rawValue, type: type, rule: transformRule(name: type.displayName))
        ))
        var result: GestureTriggerType?
        for (index, touches) in frames.enumerated() {
            let gestures = recognizer.process(frame(touches: touches, timestamp: 1.0 + Double(index) * 0.1))
            XCTAssertLessThanOrEqual(gestures.count, 1)
            result = gestures.first?.kind ?? result
        }
        return result
    }

    private func configuration(_ trigger: GestureRule) -> GestureConfiguration {
        GestureConfiguration(triggers: [trigger])
    }

    private func touchStartRule() -> TouchStartGestureRule {
        TouchStartGestureRule(
            name: "2 Finger Touch Start",
            isEnabled: true,
            fingerCount: 2,
            cooldownMilliseconds: 650,
            action: ScriptAction(language: .appleScript, script: "return true")
        )
    }

    private func holdRule(pressKind: HoldPressKind) -> HoldGestureRule {
        HoldGestureRule(
            name: "2 Finger Long Press",
            isEnabled: true,
            fingerCount: 2,
            holdMilliseconds: 100,
            maximumMovement: 0.06,
            pressKind: pressKind,
            cooldownMilliseconds: 650,
            action: ScriptAction(language: .appleScript, script: "return true")
        )
    }

    private func tapRule(pressKind: HoldPressKind) -> TapGestureRule {
        TapGestureRule(
            name: "2 Finger Tap",
            isEnabled: true,
            fingerCount: 2,
            tapCount: 1,
            maximumTapMilliseconds: 300,
            maximumMovement: 0.08,
            pressKind: pressKind,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([ScriptAction(language: .appleScript, script: "return true")])
        )
    }

    private func tipTapRule() -> TipTapGestureRule {
        TipTapGestureRule(
            name: "Tip Tap",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([ScriptAction(language: .appleScript, script: "return true")])
        )
    }

    private func transformRule(name: String) -> TwoFingerTransformGestureRule {
        TwoFingerTransformGestureRule(
            name: name,
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([ScriptAction(language: .appleScript, script: "return true")])
        )
    }

    private func frame(
        touches: [TouchPoint],
        timestamp: TimeInterval,
        clickGeneration: UInt64 = 0
    ) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: timestamp,
            frameNumber: Int(timestamp * 100),
            clickGeneration: clickGeneration
        )
    }

    private func twoTouches(x1: Double = 0.4, x2: Double = 0.6, pressure: Double = 0.7) -> [TouchPoint] {
        [touch(id: 1, x: x1, pressure: pressure), touch(id: 2, x: x2, pressure: pressure)]
    }

    private func rotateTouches(left: Bool) -> [TouchPoint] {
        left
            ? [touch(id: 1, x: 0.5, y: 0.4), touch(id: 2, x: 0.5, y: 0.6)]
            : [touch(id: 1, x: 0.5, y: 0.6), touch(id: 2, x: 0.5, y: 0.4)]
    }

    private func rotatedTouches(degrees: Double) -> [TouchPoint] {
        let radians = degrees * .pi / 180
        let offsetX = cos(radians) * 0.1
        let offsetY = sin(radians) * 0.1
        return [
            touch(id: 1, x: 0.5 - offsetX, y: 0.5 - offsetY),
            touch(id: 2, x: 0.5 + offsetX, y: 0.5 + offsetY)
        ]
    }

    private func leftRotationAnimationFrames() -> [[TouchPoint]] {
        [
            rotatedTouches(degrees: -41),
            rotatedTouches(degrees: -8),
            rotatedTouches(degrees: 41),
            [touch(id: 1, x: 0.5 - cos(41 * .pi / 180) * 0.1, y: 0.5 - sin(41 * .pi / 180) * 0.1)],
            []
        ]
    }

    private func rightRotationAnimationFrames() -> [[TouchPoint]] {
        [
            rotatedTouches(degrees: 41),
            rotatedTouches(degrees: 8),
            rotatedTouches(degrees: -41),
            [touch(id: 2, x: 0.5 + cos(-41 * .pi / 180) * 0.1, y: 0.5 + sin(-41 * .pi / 180) * 0.1)],
            []
        ]
    }

    private func swipeDriftTouches(left: Bool) -> [TouchPoint] {
        let yDrift = left ? 0.02 : -0.02
        return [
            touch(id: 1, x: 0.50, y: 0.5 - yDrift),
            touch(id: 2, x: 0.70, y: 0.5 + yDrift)
        ]
    }

    private func noisyPinchTouches(left: Bool) -> [TouchPoint] {
        let yDrift = left ? 0.01 : -0.01
        return [
            touch(id: 1, x: 0.45, y: 0.5 - yDrift),
            touch(id: 2, x: 0.55, y: 0.5 + yDrift)
        ]
    }

    private func pivotRotationTouches(degrees: Double) -> [TouchPoint] {
        let radians = degrees * .pi / 180
        return [
            touch(id: 1, x: 0.4, y: 0.5),
            touch(id: 2, x: 0.4 + cos(radians) * 0.2, y: 0.5 + sin(radians) * 0.2)
        ]
    }

    private func touch(id: Int, x: Double, y: Double = 0.5, pressure: Double = 0.7) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: pressure, size: 0.2)
    }
}
