@testable import GlissPadCore
import Foundation
import XCTest

final class WholeHandTapTimingTests: XCTestCase {
    func testTapTriggersWhenContactsReleaseOneAtATime() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 8), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 8), time: 1.12)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(count: 7), time: 1.24))

        XCTAssertEqual(gestures.map(\.kind), [.wholeHandTap])
    }

    func testFastReleaseWaitsUntilMinimumTapDuration() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 8), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 7), time: 1.01)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(count: 4), time: 1.04))

        XCTAssertEqual(gestures.map(\.kind), [.wholeHandTap])
    }

    func testDefaultTapDoesNotRequireLargeContactArea() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 8, size: 0.03), time: 1.00)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(count: 7, size: 0.03), time: 1.18))

        XCTAssertEqual(gestures.map(\.kind), [.wholeHandTap])
    }

    func testTapCountsPressurizedInRangePalmContacts() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 8, state: .hoverInRange), time: 1.00)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.18))

        XCTAssertEqual(gestures.map(\.kind), [.wholeHandTap])
    }

    func testTapIgnoresUnpressurizedInRangeContacts() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 8, state: .hoverInRange, pressure: 0), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.18)).isEmpty)
    }

    func testTapAllowsHumanReleaseDuration() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 8), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 8), time: 1.42)).isEmpty)
        let gestures = recognizer.process(frame(touches: touches(count: 7), time: 1.58))

        XCTAssertEqual(gestures.map(\.kind), [.wholeHandTap])
    }

    func testTapRejectsGestureThatNeverReachesMinimumContactCount() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 7), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.18)).isEmpty)
    }

    func testMigrationRelaxesLegacyWholeHandTapDefaults() {
        var rule = wholeHandRule()
        rule.wholeHandTap = WholeHandTapOptions(
            requireLargeContactArea: true,
            minTotalContactArea: 1.4,
            minAverageContactArea: 0.14,
            requirePalmLikeContact: true,
            palmDetectionMode: .heuristic,
            maxTapMilliseconds: 260
        )
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [.fiveAndMoreFinger(id: "whole", type: .wholeHandTap, rule: rule)]),
            debugLogging: false
        )
        let migrated = configuration.replacingBundledDefaultScripts()

        guard case .fiveAndMoreFinger(_, .wholeHandTap, let migratedRule) = migrated.gestures.triggers[0] else {
            return XCTFail("Expected whole hand tap trigger.")
        }
        XCTAssertFalse(migratedRule.wholeHandTap.requireLargeContactArea)
        XCTAssertFalse(migratedRule.wholeHandTap.requirePalmLikeContact)
        XCTAssertEqual(migratedRule.wholeHandTap.palmDetectionMode, .disabledFallback)
        XCTAssertEqual(migratedRule.wholeHandTap.maxTapMilliseconds, 700)
    }

    private func recognizer(rule: FiveAndMoreFingerGestureRule? = nil) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [
            .fiveAndMoreFinger(id: "whole", type: .wholeHandTap, rule: rule ?? wholeHandRule())
        ]))
    }

    private func wholeHandRule() -> FiveAndMoreFingerGestureRule {
        guard case .fiveAndMoreFinger(_, _, let rule) = GestureTriggerType.wholeHandTap
            .defaultTrigger(id: "whole", ordinal: 1) else {
            return FiveAndMoreFingerGestureRule(
                name: "Whole Hand Tap",
                isEnabled: true,
                cooldownMilliseconds: 650,
                actions: []
            )
        }
        return rule
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func touches(
        count: Int,
        state: TouchState = .touching,
        pressure: Double = 0.2,
        size: Double = 0.08
    ) -> [TouchPoint] {
        (0..<count).map { index in
            let row = index / 4
            let column = index % 4
            return TouchPoint(
                id: index + 1,
                state: state,
                position: NormalizedPoint(x: 0.38 + Double(column) * 0.08, y: 0.45 + Double(row) * 0.10),
                pressure: pressure,
                size: size
            )
        }
    }
}
