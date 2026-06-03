@testable import GlissPadCore
import XCTest

final class OneFingerCustomPathConfigurationTests: XCTestCase {
    func testDecodesCustomPathTrigger() throws {
        let data = """
        {
          "triggers": [{
            "id": "path",
            "type": "oneFingerCustomPath",
            "customPath": {
              "name": "Triangle",
              "isEnabled": true,
              "points": [
                { "x": 0.2, "y": 0.8 },
                { "x": 0.5, "y": 0.2 },
                { "x": 0.8, "y": 0.8 }
              ],
              "pointTolerance": 0.08,
              "cooldownMilliseconds": 650,
              "actions": [{
                "type": "testHUD",
                "name": "HUD",
                "title": "Path",
                "detail": "Matched"
              }]
            }
          }]
        }
        """.data(using: .utf8)!

        let configuration = try JSONDecoder().decode(GestureConfiguration.self, from: data)
        try configuration.validate()

        guard case .customPath(_, .oneFingerCustomPath, let rule)? = configuration.triggers.first else {
            return XCTFail("Expected custom path trigger.")
        }
        XCTAssertEqual(rule.name, "Triangle")
        XCTAssertEqual(rule.points.count, 3)
        XCTAssertEqual(rule.pointTolerance, 0.08)
    }

    func testRejectsSinglePointPath() {
        let rule = CustomPathGestureRule(
            name: "Path",
            isEnabled: true,
            points: [NormalizedPoint(x: 0.5, y: 0.5)],
            cooldownMilliseconds: 650,
            actions: [.script(ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript))]
        )
        let configuration = GestureConfiguration(triggers: [
            .customPath(id: "path", type: .oneFingerCustomPath, rule: rule)
        ])

        XCTAssertThrowsError(try configuration.validate())
    }

    func testDecodesDrawnCustomPathTrigger() throws {
        let data = """
        {
          "triggers": [{
            "id": "drawn",
            "type": "oneFingerDrawnPath",
            "customPath": {
              "name": "Drawn Shape",
              "isEnabled": true,
              "points": [
                { "x": 0.2, "y": 0.5 },
                { "x": 0.4, "y": 0.7 },
                { "x": 0.7, "y": 0.4 }
              ],
              "pointTolerance": 0.09,
              "cooldownMilliseconds": 650,
              "actions": [{
                "type": "testHUD",
                "name": "HUD",
                "title": "Path",
                "detail": "Matched"
              }]
            }
          }]
        }
        """.data(using: .utf8)!

        let configuration = try JSONDecoder().decode(GestureConfiguration.self, from: data)
        try configuration.validate()

        guard case .customPath(_, .oneFingerDrawnPath, let rule)? = configuration.triggers.first else {
            return XCTFail("Expected drawn custom path trigger.")
        }
        XCTAssertEqual(rule.name, "Drawn Shape")
        XCTAssertEqual(rule.pointTolerance, 0.09)
    }
}
