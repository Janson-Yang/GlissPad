@testable import GlissPadCore
import XCTest

final class ThreeFingerGestureRecognizerTests: XCTestCase {
    func testTouchStartTriggersWhenThreeFingersArrive() {
        let recognizer = recognizer(.threeFingerTouch)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.04))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTouch])
    }

    func testTapTriggersAfterRelease() {
        let recognizer = recognizer(.threeFingerTap)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.1))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTap])
    }

    func testInitialFingerGapRejectsSlowThreeFingerArrival() {
        var rule = threeFingerRule(.threeFingerTap)
        rule.common = ThreeFingerCommonOptions(
            maxInitialFingerTimeGapMilliseconds: 50,
            minStableFingerCountDurationMilliseconds: 0
        )
        let recognizer = recognizer(.threeFingerTap, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.3, y: 0.5)], time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.02)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.12))

        XCTAssertTrue(gestures.isEmpty)
    }

    func testLongTouchRepeatsAtConfiguredRepeatInterval() {
        var rule = threeFingerRule(.threeFingerTouch)
        rule.touch = ThreeFingerTouchOptions(
            event: .longTouch,
            holdMilliseconds: 100,
            repeatWhileHolding: true,
            repeatIntervalMilliseconds: 120
        )
        let recognizer = recognizer(.threeFingerTouch, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.04)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.15)).map(\.kind), [.threeFingerTouch])
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.22)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.28)).map(\.kind), [.threeFingerTouch])
    }

    func testTouchEndTriggersWhenReleaseStartsOneFingerAtATime() {
        var rule = threeFingerRule(.threeFingerTouch)
        rule.touch = ThreeFingerTouchOptions(event: .touchEnd)
        let recognizer = recognizer(.threeFingerTouch, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.12))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTouch])
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.14)).isEmpty)
    }

    func testLongTouchThresholdCanTriggerWhenReleaseStartsAfterQuietHold() {
        var rule = threeFingerRule(.threeFingerTouch)
        rule.touch = ThreeFingerTouchOptions(event: .longTouch, holdMilliseconds: 100)
        let recognizer = recognizer(.threeFingerTouch, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.2))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTouch])
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.22)).isEmpty)
    }

    func testLongTouchCanTriggerOnReleaseAfterHoldThreshold() {
        var rule = threeFingerRule(.threeFingerTouch)
        rule.touch = ThreeFingerTouchOptions(
            event: .longTouch,
            holdMilliseconds: 100,
            triggerTiming: .release
        )
        let recognizer = recognizer(.threeFingerTouch, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.04)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.4, 0.5), time: 1.2)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.24))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTouch])
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.26)).isEmpty)
    }

    func testPressCanRequireRightFingerPressureBias() {
        var rule = threeFingerRule(.threeFingerPress)
        rule.press = ThreeFingerPressOptions(level: .force, pressureBias: .right)
        let recognizer = recognizer(.threeFingerPress, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: biasedPressures(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: biasedPressures(), time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: biasedPressures(), time: 1.06))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerPress])
    }

    func testSwipeTriggersOnDirectionalMovement() {
        var rule = threeFingerRule(.threeFingerSwipe)
        rule.swipe = ThreeFingerSwipeOptions(direction: .right, minimumTravel: 0.16, minimumVelocity: 0.5)
        let recognizer = recognizer(.threeFingerSwipe, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.25, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.25, 0.5), time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(at: 0.55, 0.5), time: 1.2))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerSwipe])
    }

    func testTipTapTriggersWhenThirdFingerTapsWhileTwoStayFixed() {
        var rule = threeFingerRule(.threeFingerTipTap)
        rule.tipTap = ThreeFingerTipTapOptions(tapPosition: .right)
        let recognizer = recognizer(.threeFingerTipTap, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.5)], time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.14))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipTap])
    }

    func testTipTapCountRequiresSecondTipTapWhenConfigured() {
        var rule = threeFingerRule(.threeFingerTipTap)
        rule.tipTap = ThreeFingerTipTapOptions(tapPosition: .right, tapCount: 2)
        let recognizer = recognizer(.threeFingerTipTap, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.5)], time: 1.08)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.14)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [touch(id: 4, x: 0.7, y: 0.5)], time: 1.2)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.24))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipTap])
    }

    func testTipSwipeTriggersWhenThirdFingerMovesAndTwoStayFixed() {
        let recognizer = recognizer(.threeFingerTipSwipe)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.5)], time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.3)], time: 1.26))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipSwipe])
    }

    func testTipSwipeCanTriggerOnRelease() {
        var rule = threeFingerRule(.threeFingerTipSwipe)
        rule.tipSwipe = ThreeFingerTipSwipeOptions(triggerTiming: .release)
        let recognizer = recognizer(.threeFingerTipSwipe, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches(), time: 1.06)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.5)], time: 1.08)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: baseTouches() + [touch(id: 3, x: 0.7, y: 0.3)], time: 1.26)).isEmpty)
        let gestures = recognizer.process(frame(touches: baseTouches(), time: 1.28))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTipSwipe])
    }

    func testSwipeContinuousTimingRepeatsAfterCooldown() {
        var rule = threeFingerRule(.threeFingerSwipe)
        rule.cooldownMilliseconds = 100
        rule.swipe = ThreeFingerSwipeOptions(
            direction: .right,
            minimumTravel: 0.16,
            minimumVelocity: 0.5,
            triggerTiming: .continuous
        )
        let recognizer = recognizer(.threeFingerSwipe, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.25, 0.5), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.25, 0.5), time: 1.04)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: touches(at: 0.55, 0.5), time: 1.2)).map(\.kind), [.threeFingerSwipe])
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.6, 0.5), time: 1.25)).isEmpty)
        XCTAssertEqual(recognizer.process(frame(touches: touches(at: 0.65, 0.5), time: 1.31)).map(\.kind), [.threeFingerSwipe])
    }

    func testScaleBeatsSwipeWhenBothMatchSameFrame() {
        let recognizer = GestureRecognizer(configuration: GestureConfiguration(triggers: [
            trigger(.threeFingerSwipe),
            trigger(.thumbTwoFingerScale)
        ]))

        XCTAssertTrue(recognizer.process(frame(touches: spreadStart(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: spreadStart(), time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: spreadEnd(), time: 1.2))

        XCTAssertEqual(gestures.map(\.kind), [.thumbTwoFingerScale])
    }

    func testDrawingMatchesConfiguredTemplateOnRelease() {
        let recognizer = recognizer(.threeFingerDrawing)

        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.1), time: 1.04)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.2, 0.8), time: 1.4)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(at: 0.7, 0.8), time: 1.7)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.8))

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerDrawing])
    }

    func testDrawingScaleNormalizationControlsTemplateMatching() {
        var normalizedRule = threeFingerRule(.threeFingerDrawing)
        normalizedRule.drawing.normalizeScale = true
        let normalized = recognizer(.threeFingerDrawing, rule: normalizedRule)

        XCTAssertTrue(normalized.process(frame(touches: touches(at: 0.1, 0.1), time: 1.0)).isEmpty)
        XCTAssertTrue(normalized.process(frame(touches: touches(at: 0.1, 0.1), time: 1.04)).isEmpty)
        XCTAssertTrue(normalized.process(frame(touches: touches(at: 0.1, 0.9), time: 1.4)).isEmpty)
        XCTAssertTrue(normalized.process(frame(touches: touches(at: 0.67, 0.9), time: 1.7)).isEmpty)
        XCTAssertEqual(normalized.process(frame(touches: [], time: 1.8)).map(\.kind), [.threeFingerDrawing])

        var absoluteRule = threeFingerRule(.threeFingerDrawing)
        absoluteRule.drawing.normalizeScale = false
        let absolute = recognizer(.threeFingerDrawing, rule: absoluteRule)

        XCTAssertTrue(absolute.process(frame(touches: touches(at: 0.1, 0.1), time: 2.0)).isEmpty)
        XCTAssertTrue(absolute.process(frame(touches: touches(at: 0.1, 0.1), time: 2.04)).isEmpty)
        XCTAssertTrue(absolute.process(frame(touches: touches(at: 0.1, 0.9), time: 2.4)).isEmpty)
        XCTAssertTrue(absolute.process(frame(touches: touches(at: 0.67, 0.9), time: 2.7)).isEmpty)
        XCTAssertTrue(absolute.process(frame(touches: [], time: 2.8)).isEmpty)
    }

    func testDrawingRotationNormalizationControlsTemplateMatching() {
        var rotatedRule = threeFingerRule(.threeFingerDrawing)
        rotatedRule.drawing = ThreeFingerDrawingOptions(
            template: ThreeFingerDrawingTemplate(
                id: "horizontal",
                name: "Horizontal",
                points: [NormalizedPoint(x: 0.2, y: 0.2), NormalizedPoint(x: 0.8, y: 0.2)]
            ),
            minimumPathLength: 0.1,
            normalizeRotation: true
        )
        let rotated = recognizer(.threeFingerDrawing, rule: rotatedRule)

        XCTAssertTrue(rotated.process(frame(touches: touches(at: 0.2, 0.2), time: 1.0)).isEmpty)
        XCTAssertTrue(rotated.process(frame(touches: touches(at: 0.2, 0.2), time: 1.04)).isEmpty)
        XCTAssertTrue(rotated.process(frame(touches: touches(at: 0.2, 0.8), time: 1.4)).isEmpty)
        XCTAssertEqual(rotated.process(frame(touches: [], time: 1.5)).map(\.kind), [.threeFingerDrawing])

        var strictRule = rotatedRule
        strictRule.drawing.normalizeRotation = false
        let strict = recognizer(.threeFingerDrawing, rule: strictRule)

        XCTAssertTrue(strict.process(frame(touches: touches(at: 0.2, 0.2), time: 2.0)).isEmpty)
        XCTAssertTrue(strict.process(frame(touches: touches(at: 0.2, 0.2), time: 2.04)).isEmpty)
        XCTAssertTrue(strict.process(frame(touches: touches(at: 0.2, 0.8), time: 2.4)).isEmpty)
        XCTAssertTrue(strict.process(frame(touches: [], time: 2.5)).isEmpty)
    }

    func testHeuristicThumbScaleUsesLargestTouchAsThumb() {
        var rule = threeFingerRule(.thumbTwoFingerScale)
        rule.scale = ThreeFingerScaleOptions(
            direction: .spreadOut,
            minimumScaleDelta: 0.4,
            thumbDetectionMode: .heuristic
        )
        let recognizer = recognizer(.thumbTwoFingerScale, rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: thumbScaleStart(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: thumbScaleStart(), time: 1.04)).isEmpty)
        let gestures = recognizer.process(frame(touches: thumbScaleEnd(), time: 1.3))

        XCTAssertEqual(gestures.map(\.kind), [.thumbTwoFingerScale])
    }

}
