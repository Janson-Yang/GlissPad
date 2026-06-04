@testable import GlissPadCore
import XCTest

final class ThreeFingerTipSwipeMigrationTests: XCTestCase {
    func testMigratesLegacyDefaultVelocity() {
        var rule = ThreeFingerGestureRule(
            name: "TipSwipe",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(title: "ok"))]
        )
        rule.tipSwipe = ThreeFingerTipSwipeOptions(minimumVelocity: 0.75)
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                .threeFinger(id: "tip-swipe", type: .threeFingerTipSwipe, rule: rule)
            ]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(tipSwipeVelocity(in: migrated.gestures.triggers[0]), 0.35)
    }

    func testKeepsCustomVelocity() {
        var rule = ThreeFingerGestureRule(
            name: "TipSwipe",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(title: "ok"))]
        )
        rule.tipSwipe = ThreeFingerTipSwipeOptions(minimumVelocity: 0.5)
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                .threeFinger(id: "tip-swipe", type: .threeFingerTipSwipe, rule: rule)
            ]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(tipSwipeVelocity(in: migrated.gestures.triggers[0]), 0.5)
    }

    private func tipSwipeVelocity(in trigger: GestureRule) -> Double? {
        guard case .threeFinger(_, .threeFingerTipSwipe, let rule) = trigger else { return nil }
        return rule.tipSwipe.minimumVelocity
    }
}
