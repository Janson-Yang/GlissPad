@testable import GlissPadCore
import XCTest

final class ThreeFingerTouchMigrationTests: XCTestCase {
    func testMigratesLegacyTouchToleranceOnly() {
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                touchTrigger(id: "legacy", event: .touchEnd, tolerance: 0.04),
                touchTrigger(id: "custom", event: .longTouch, tolerance: 0.12)
            ]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(tolerance(in: migrated.gestures.triggers[0]), 0.08)
        XCTAssertEqual(tolerance(in: migrated.gestures.triggers[1]), 0.12)
    }

    private func touchTrigger(id: String, event: ThreeFingerTouchEvent, tolerance: Double) -> GestureRule {
        var rule = ThreeFingerGestureRule(
            name: "Three Finger Touch",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: [.script(scriptAction())]
        )
        rule.touch = ThreeFingerTouchOptions(event: event, movementTolerance: tolerance)
        return .threeFinger(id: id, type: .threeFingerTouch, rule: rule)
    }

    private func tolerance(in trigger: GestureRule) -> Double? {
        guard case .threeFinger(_, .threeFingerTouch, let rule) = trigger else { return nil }
        return rule.touch.movementTolerance
    }

    private func scriptAction() -> ScriptAction {
        ScriptAction(language: .appleScript, script: "return true", timeoutSeconds: 5)
    }
}
