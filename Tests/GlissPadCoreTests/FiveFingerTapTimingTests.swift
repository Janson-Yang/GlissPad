@testable import GlissPadCore
import Foundation
import XCTest

final class FiveFingerTapTimingTests: XCTestCase {
    func testTapToleratesExtraContactNoise() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 6), time: 1.00)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.18))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTap])
    }

    func testTapToleratesPressureNoiseWithoutClickEvent() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5, pressure: 1.1), time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.16))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTap])
    }

    func testTapStillCancelsOnRealClickEvent() {
        let recognizer = recognizer()

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.08, clickGeneration: 1)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [], time: 1.16)).isEmpty)
    }

    func testTapUsesFiveFingerMinimumTapWindow() {
        var rule = fiveFingerRule()
        rule.tap.maximumTapMilliseconds = 200
        let recognizer = recognizer(rule: rule)

        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.00)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches(count: 5), time: 1.08)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], time: 1.36))

        XCTAssertEqual(gestures.map(\.kind), [.fiveFingerTap])
    }

    func testMigrationRaisesLegacyDefaultTapParameters() {
        var rule = fiveFingerRule()
        rule.tap = ThreeFingerTapOptions(
            maximumTapMilliseconds: 200,
            maximumMovement: 0.08,
            maximumInterTapIntervalMilliseconds: 280
        )
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [.fiveAndMoreFinger(id: "tap", type: .fiveFingerTap, rule: rule)]),
            debugLogging: false
        )
        let migrated = configuration.replacingBundledDefaultScripts()

        guard case .fiveAndMoreFinger(_, .fiveFingerTap, let migratedRule) = migrated.gestures.triggers[0] else {
            return XCTFail("Expected five finger tap trigger.")
        }
        XCTAssertEqual(migratedRule.tap.maximumTapMilliseconds, 320)
        XCTAssertEqual(migratedRule.tap.maximumMovement, 0.10)
        XCTAssertEqual(migratedRule.tap.maximumInterTapIntervalMilliseconds, 320)
    }

    private func recognizer(rule: FiveAndMoreFingerGestureRule? = nil) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [
            .fiveAndMoreFinger(id: "five-tap", type: .fiveFingerTap, rule: rule ?? fiveFingerRule())
        ]))
    }

    private func fiveFingerRule() -> FiveAndMoreFingerGestureRule {
        guard case .fiveAndMoreFinger(_, _, let rule) = GestureTriggerType.fiveFingerTap
            .defaultTrigger(id: "five-tap", ordinal: 1) else {
            return FiveAndMoreFingerGestureRule(
                name: "Five Finger Tap",
                isEnabled: true,
                cooldownMilliseconds: 650,
                actions: []
            )
        }
        return rule
    }

    private func frame(
        touches: [TouchPoint],
        time: TimeInterval,
        clickGeneration: UInt64 = 0
    ) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: time,
            frameNumber: Int(time * 100),
            clickGeneration: clickGeneration
        )
    }

    private func touches(count: Int, pressure: Double = 0.2) -> [TouchPoint] {
        (0..<count).map { index in
            let offset = Double(index) - Double(count - 1) / 2
            return TouchPoint(
                id: index + 1,
                state: .touching,
                position: NormalizedPoint(x: 0.5 + offset * 0.03, y: 0.5),
                pressure: pressure,
                size: 0.2
            )
        }
    }
}
