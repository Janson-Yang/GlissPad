@testable import GlissPadCore
import XCTest

final class TestHUDBrandMigrationTests: XCTestCase {
    func testMigratesLegacyTestHUDTitle() {
        let action = TestHUDAction(
            name: "HUD",
            title: legacyInitialBrandTitle(),
            detail: "Trigger fired."
        )
        XCTAssertMigratesLegacyTitle(action)
    }

    func testMigratesPreviousBrandTestHUDTitle() {
        let action = TestHUDAction(
            name: "HUD",
            title: legacyPreviousBrandTitle(),
            detail: "Trigger fired."
        )
        XCTAssertMigratesLegacyTitle(action)
    }

    private func XCTAssertMigratesLegacyTitle(
        _ action: TestHUDAction,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let trigger = GestureTriggerType.twoFingerTap
            .defaultTrigger(id: "tap", ordinal: 1)
            .replacingActions([.testHUD(action)])
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [trigger]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(
            migrated.gestures.triggers[0].actions[0].testHUDAction?.title,
            "GlissPad Test HUD",
            file: file,
            line: line
        )
    }

    private func legacyPreviousBrandTitle() -> String {
        [["Tap", "line"].joined(), "Test HUD"].joined(separator: " ")
    }

    private func legacyInitialBrandTitle() -> String {
        ["Simple", ["B", "T", "T"].joined(), "Test HUD"].joined(separator: " ")
    }
}
