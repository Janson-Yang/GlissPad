@testable import GlissPadCore
import XCTest

final class OneFingerPressConfigurationTests: XCTestCase {
    func testDecodesOneFingerPressTrigger() throws {
        let data = """
        {
          "triggers": [{
            "id": "press",
            "type": "oneFingerPress",
            "oneFingerPress": {
              "name": "Audio Press",
              "isEnabled": true,
              "pressKind": "forceClick",
              "minimumPressure": 0.9,
              "minimumForceMilliseconds": 60,
              "maximumMovement": 0.03,
              "cooldownMilliseconds": 700,
              "actions": [{
                "type": "testHUD",
                "name": "HUD",
                "title": "Triggered",
                "detail": "One finger press"
              }]
            }
          }]
        }
        """.data(using: .utf8)!

        let configuration = try JSONDecoder().decode(GestureConfiguration.self, from: data)
        try configuration.validate()

        guard case .oneFingerPress(_, .oneFingerPress, let rule)? = configuration.triggers.first else {
            return XCTFail("Expected one finger press trigger.")
        }
        XCTAssertEqual(rule.name, "Audio Press")
        XCTAssertEqual(rule.pressKind, .forceClick)
        XCTAssertEqual(rule.minimumPressure, 0.9)
        XCTAssertEqual(rule.maximumMovement, 0.03)
    }

    func testRejectsInvalidMovementTolerance() {
        let rule = OneFingerPressGestureRule(
            name: "Press",
            isEnabled: true,
            pressKind: .click,
            maximumMovement: 0.9,
            cooldownMilliseconds: 650,
            actions: [.script(ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript))]
        )
        let configuration = GestureConfiguration(triggers: [
            .oneFingerPress(id: "press", type: .oneFingerPress, rule: rule)
        ])

        XCTAssertThrowsError(try configuration.validate())
    }
}
