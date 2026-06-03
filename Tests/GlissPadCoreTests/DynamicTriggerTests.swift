@testable import GlissPadCore
import Foundation
import XCTest

final class DynamicTriggerTests: XCTestCase {
    func testConfigurationKeepsDuplicateTriggerTypes() throws {
        let configuration = duplicateThreeFingerConfiguration()

        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(GestureConfiguration.self, from: data)

        XCTAssertEqual(decoded.triggers.map(\.id), ["voice-start", "voice-stop"])
        XCTAssertEqual(decoded.triggers.map(\.type), [.threeFingerForcePress, .threeFingerForcePress])
        XCTAssertEqual(decoded.triggers.map(\.name), ["Voice Start", "Voice Stop"])
        try decoded.validate()
    }

    func testConfigurationAllowsNoTriggers() throws {
        try GestureConfiguration(triggers: []).validate()
    }

    func testRecognizerEmitsEachMatchingTriggerInstance() {
        let recognizer = GestureRecognizer(configuration: duplicateThreeFingerConfiguration())
        let touches = threeFingerTouches(pressure: TrackpadPressureThreshold.forceClick)

        XCTAssertTrue(recognizer.process(frame(touches: touches, timestamp: 1.0, clickGeneration: 1)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: touches, timestamp: 1.1, clickGeneration: 2)).isEmpty)
        let gestures = recognizer.process(frame(touches: [], timestamp: 1.12, clickGeneration: 2))

        XCTAssertEqual(gestures.map(\.id), ["voice-start", "voice-stop"])
        XCTAssertEqual(gestures.map(\.name), ["Voice Start", "Voice Stop"])
    }

    func testClickSuppressionCombinesEnabledDuplicateThreeFingerTriggers() {
        var first = GestureConfiguration.default.threeFingerForcePress
        var second = first
        first.isEnabled = false
        second.name = "Secondary"
        second.minimumPressure = 0.72
        second.sustainingPressure = 0.62
        second.minimumForceMilliseconds = 40
        second.maximumMovement = 0.08

        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                .press(id: "disabled", type: .threeFingerForcePress, rule: first),
                .press(id: "enabled", type: .threeFingerForcePress, rule: second)
            ]),
            debugLogging: false
        )

        XCTAssertEqual(
            GestureRuntime.clickSuppressionRule(for: configuration),
            ClickSuppressionRule(
                fingerCount: 3,
                minimumPressure: 0.72,
                sustainingPressure: 0.62,
                minimumForceMilliseconds: 40,
                maximumMovement: 0.08
            )
        )
    }

    private func duplicateThreeFingerConfiguration() -> GestureConfiguration {
        let base = GestureConfiguration.default.threeFingerForcePress
        return GestureConfiguration(triggers: [
            .press(id: "voice-start", type: .threeFingerForcePress, rule: named(base, "Voice Start")),
            .press(id: "voice-stop", type: .threeFingerForcePress, rule: named(base, "Voice Stop"))
        ])
    }

    private func named(_ rule: PressGestureRule, _ name: String) -> PressGestureRule {
        var rule = rule
        rule.name = name
        return rule
    }

    private func threeFingerTouches(pressure: Double) -> [TouchPoint] {
        [
            touch(id: 1, x: 0.2, y: 0.3, pressure: pressure),
            touch(id: 2, x: 0.3, y: 0.3, pressure: pressure),
            touch(id: 3, x: 0.4, y: 0.3, pressure: pressure)
        ]
    }

    private func frame(
        touches: [TouchPoint],
        timestamp: TimeInterval,
        clickGeneration: UInt64
    ) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: timestamp,
            frameNumber: Int(timestamp * 100),
            clickGeneration: clickGeneration,
            hasRecentClick: false
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
