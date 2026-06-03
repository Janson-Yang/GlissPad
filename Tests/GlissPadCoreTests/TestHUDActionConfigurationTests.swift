@testable import GlissPadCore
import Foundation
import XCTest

final class TestHUDActionConfigurationTests: XCTestCase {
    func testDecodesTestHUDAction() throws {
        let action = try JSONDecoder().decode(GestureAction.self, from: Data(Self.actionJSON.utf8))

        guard case .testHUD(let testHUDAction) = action else {
            return XCTFail("Expected test HUD action.")
        }
        XCTAssertEqual(testHUDAction.name, "HUD Probe")
        XCTAssertEqual(testHUDAction.title, "Trigger fired")
        XCTAssertEqual(testHUDAction.detail, "Release trigger matched.")
        XCTAssertNoThrow(try action.validate(name: "action"))
    }

    func testDefaultNameUsesDisplayName() {
        let action = GestureAction.testHUD(TestHUDAction()).defaultNamed(index: 1)

        XCTAssertEqual(action.name, "Pop up a test HUD 2")
        XCTAssertEqual(action.typeDisplayName, "Pop up a test HUD")
    }

    private static let actionJSON = """
    {
      "type": "testHUD",
      "name": "HUD Probe",
      "title": "Trigger fired",
      "detail": "Release trigger matched."
    }
    """
}
