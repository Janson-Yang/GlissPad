@testable import GlissPadCore
import XCTest

final class ConfigurationImportMergerTests: XCTestCase {
    func testDetectsNameConflictsCaseInsensitively() {
        let conflicts = ConfigurationImportMerger.conflictingNames(
            current: [trigger(name: "Audio Input", id: "current")],
            imported: [trigger(name: " audio input ", id: "imported")]
        )

        XCTAssertEqual(conflicts, [" audio input "])
    }

    func testReplaceKeepsExistingIdentifierAndPosition() throws {
        let current = trigger(name: "Audio Input", id: "current")
        let imported = trigger(name: "Audio Input", id: "imported", type: .twoFingerTap)

        let result = ConfigurationImportMerger.merge(
            current: [current],
            imported: [imported],
            resolution: .replace
        )

        XCTAssertEqual(result.replacedCount, 1)
        XCTAssertEqual(result.triggers[0].id, "current")
        XCTAssertEqual(result.triggers[0].type, .twoFingerTap)
        try GestureConfiguration(triggers: result.triggers).validate()
    }

    func testSkipLeavesCurrentTriggerUnchanged() {
        let current = trigger(name: "Audio Input", id: "current")
        let imported = trigger(name: "Audio Input", id: "imported", type: .twoFingerTap)

        let result = ConfigurationImportMerger.merge(
            current: [current],
            imported: [imported],
            resolution: .skip
        )

        XCTAssertEqual(result.skippedCount, 1)
        XCTAssertEqual(result.triggers, [current])
    }

    func testKeepBothRenamesImportedTriggerAndRegeneratesConflictingIdentifier() throws {
        let current = trigger(name: "Audio Input", id: "same-id")
        let imported = trigger(name: "Audio Input", id: "same-id", type: .twoFingerTap)

        let result = ConfigurationImportMerger.merge(
            current: [current],
            imported: [imported],
            resolution: .keepBoth
        )

        XCTAssertEqual(result.addedCount, 1)
        XCTAssertEqual(result.renamedCount, 1)
        XCTAssertEqual(result.triggers.map(\.name), ["Audio Input", "Audio Input 2"])
        XCTAssertNotEqual(result.triggers[1].id, "same-id")
        try GestureConfiguration(triggers: result.triggers).validate()
    }

    private func trigger(
        name: String,
        id: String,
        type: GestureTriggerType = .oneFingerTap
    ) -> GestureRule {
        type.defaultTrigger(id: id, ordinal: 1)
            .replacingName(name)
            .replacingActions([])
    }
}
