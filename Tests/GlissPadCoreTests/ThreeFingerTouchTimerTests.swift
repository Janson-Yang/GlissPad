@testable import GlissPadCore
import Foundation
import XCTest

final class ThreeFingerTouchTimerTests: XCTestCase {
    func testLongTouchRecognizerTriggersFromTimerAfterQuietHold() {
        let recognizer = GestureRecognizer(configuration: configuration(holdMilliseconds: 100, stableMilliseconds: 30))

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertEqual(recognizer.nextTimerDeadline() ?? 0, 1.03, accuracy: 0.001)
        XCTAssertTrue(recognizer.processTimer(at: 1.03).isEmpty)
        XCTAssertEqual(recognizer.nextTimerDeadline() ?? 0, 1.13, accuracy: 0.001)

        let gestures = recognizer.processTimer(at: 1.13)

        XCTAssertEqual(gestures.map(\.kind), [.threeFingerTouch])
        XCTAssertNil(recognizer.nextTimerDeadline())
    }

    func testPipelineRunsLongTouchActionWithoutAdditionalFrames() {
        let actionRunner = RecordingActionRunner(expectedCount: 1)
        let pipeline = GesturePipeline(
            recognizer: GestureRecognizer(configuration: configuration(holdMilliseconds: 80, stableMilliseconds: 0)),
            actionRunner: actionRunner,
            logger: Logger(debugEnabled: false)
        )

        pipeline.handle(frame(touches: touches(), time: 10.0))

        wait(for: [actionRunner.expectation], timeout: 1)
        XCTAssertEqual(actionRunner.recordedActionCounts, [1])
    }

    func testLongTouchAllowsHumanFingerArrivalGap() {
        let recognizer = GestureRecognizer(configuration: configuration(
            holdMilliseconds: 100,
            stableMilliseconds: 0,
            initialGapMilliseconds: 80
        ))

        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.36)], time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.36), touch(id: 2, x: 0.40)], time: 1.12)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.25)).isEmpty)
        XCTAssertEqual(recognizer.nextTimerDeadline() ?? 0, 1.35, accuracy: 0.001)

        XCTAssertEqual(recognizer.processTimer(at: 1.35).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchIgnoresPartialFingerCollectionGap() {
        let recognizer = GestureRecognizer(configuration: configuration(
            holdMilliseconds: 100,
            stableMilliseconds: 0,
            initialGapMilliseconds: 80
        ))

        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.36)], time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [touch(id: 1, x: 0.36), touch(id: 2, x: 0.40)], time: 1.5)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 2.0)).isEmpty)
        XCTAssertEqual(recognizer.nextTimerDeadline() ?? 0, 2.1, accuracy: 0.001)

        XCTAssertEqual(recognizer.processTimer(at: 2.1).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchUsesCentroidWhenTouchIdentifiersChange() {
        let recognizer = GestureRecognizer(configuration: configuration(holdMilliseconds: 100, stableMilliseconds: 0))
        let changedIDs = [
            touch(id: 10, x: 0.361),
            touch(id: 11, x: 0.401),
            touch(id: 12, x: 0.441)
        ]

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: changedIDs, time: 1.05)).isEmpty)

        XCTAssertEqual(recognizer.processTimer(at: 1.1).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchAllowsModerateCentroidDrift() {
        let recognizer = GestureRecognizer(configuration: configuration(
            holdMilliseconds: 100,
            stableMilliseconds: 0,
            movementTolerance: 0.08
        ))

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(xOffset: 0.06), time: 1.05)).isEmpty)

        XCTAssertEqual(recognizer.processTimer(at: 1.1).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchRecoversFromBriefFingerDrop() {
        let recognizer = GestureRecognizer(configuration: configuration(holdMilliseconds: 100, stableMilliseconds: 0))

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.05)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.10)).isEmpty)

        XCTAssertEqual(recognizer.processTimer(at: 1.10).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchRecoversFromLongerFingerDrop() {
        let recognizer = GestureRecognizer(configuration: configuration(holdMilliseconds: 300, stableMilliseconds: 0))

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: Array(touches().prefix(2)), time: 1.10)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.38)).isEmpty)

        XCTAssertEqual(recognizer.processTimer(at: 1.38).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchIgnoresRecentClickFlagFromBeforeTracking() {
        let recognizer = GestureRecognizer(configuration: configuration(holdMilliseconds: 100, stableMilliseconds: 0))

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0, hasRecentClick: true)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.05, hasRecentClick: true)).isEmpty)

        XCTAssertEqual(recognizer.processTimer(at: 1.1).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchIgnoresLightClickGeneration() {
        let recognizer = GestureRecognizer(configuration: configuration(holdMilliseconds: 100, stableMilliseconds: 0))

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(pressure: 0.8), time: 1.05, clickGeneration: 1)).isEmpty)

        XCTAssertEqual(recognizer.processTimer(at: 1.1).map(\.kind), [.threeFingerTouch])
    }

    func testLongTouchCancelsOnPressPressureThreshold() {
        let recognizer = GestureRecognizer(configuration: configuration(holdMilliseconds: 100, stableMilliseconds: 0))

        XCTAssertTrue(recognizer.process(frame(touches: touches(), time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(pressure: 1.0), time: 1.05)).isEmpty)

        XCTAssertTrue(recognizer.processTimer(at: 1.1).isEmpty)
    }

    private func configuration(
        holdMilliseconds: Int,
        stableMilliseconds: Int,
        initialGapMilliseconds: Int = 80,
        movementTolerance: Double = 0.08
    ) -> GestureConfiguration {
        var rule = ThreeFingerGestureRule(
            name: "Long Touch",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(name: "HUD"))]
        )
        rule.common = ThreeFingerCommonOptions(
            maxInitialFingerTimeGapMilliseconds: initialGapMilliseconds,
            minStableFingerCountDurationMilliseconds: stableMilliseconds
        )
        rule.touch = ThreeFingerTouchOptions(
            event: .longTouch,
            holdMilliseconds: holdMilliseconds,
            movementTolerance: movementTolerance
        )
        return GestureConfiguration(triggers: [.threeFinger(id: "long-touch", type: .threeFingerTouch, rule: rule)])
    }

    private func frame(
        touches: [TouchPoint],
        time: TimeInterval,
        clickGeneration: UInt64 = 0,
        hasRecentClick: Bool = false
    ) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: time,
            frameNumber: Int(time * 100),
            clickGeneration: clickGeneration,
            hasRecentClick: hasRecentClick
        )
    }

    private func touches(xOffset: Double = 0, pressure: Double = 0.2) -> [TouchPoint] {
        [
            touch(id: 1, x: 0.36 + xOffset, pressure: pressure),
            touch(id: 2, x: 0.40 + xOffset, pressure: pressure),
            touch(id: 3, x: 0.44 + xOffset, pressure: pressure)
        ]
    }

    private func touch(id: Int, x: Double, pressure: Double = 0.2) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: 0.5),
            pressure: pressure,
            size: 0.2
        )
    }
}

private final class RecordingActionRunner: ActionRunning, @unchecked Sendable {
    let expectation: XCTestExpectation
    private let lock = NSLock()
    private var actionCounts: [Int] = []

    init(expectedCount: Int) {
        expectation = XCTestExpectation(description: "timed gesture actions executed")
        expectation.expectedFulfillmentCount = expectedCount
    }

    var recordedActionCounts: [Int] {
        lock.withLock { actionCounts }
    }

    func run(_ actions: [GestureAction]) {
        lock.withLock {
            actionCounts.append(actions.count)
        }
        expectation.fulfill()
    }
}
