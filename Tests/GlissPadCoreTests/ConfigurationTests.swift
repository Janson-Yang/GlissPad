@testable import GlissPadCore
import Foundation
import XCTest

final class ConfigurationTests: XCTestCase {
    func testGestureRuleCopyCanReplaceIdentifierAndName() {
        let rule = GestureTriggerType.twoFingerTap.defaultTrigger(id: "old-id", ordinal: 1)
        let copiedRule = rule
            .replacingIdentifier("new-id")
            .replacingName("Copied Tap")

        XCTAssertEqual(copiedRule.id, "new-id")
        XCTAssertEqual(copiedRule.name, "Copied Tap")
        XCTAssertEqual(copiedRule.type, .twoFingerTap)
        XCTAssertEqual(copiedRule.actions, rule.actions)
    }

    func testGestureActionCopyCanReplaceName() {
        let action = GestureAction.keyboardShortcut(KeyboardShortcutAction(
            name: "Original Shortcut",
            mode: .singleKey,
            primaryKey: .a
        ))

        let copiedAction = action.replacingName("Copied Shortcut")

        XCTAssertEqual(copiedAction.name, "Copied Shortcut")
        XCTAssertEqual(copiedAction.typeDisplayName, action.typeDisplayName)
    }

    func testInvalidConfigurationRejectsOutOfRangeRegion() {
        let rule = PressGestureRule(
            name: "test",
            isEnabled: true,
            fingerCount: 1,
            minimumPressure: 0.5,
            cooldownMilliseconds: 500,
            region: NormalizedRegion(minX: 0.8, maxX: 1.2, minY: 0.0, maxY: 1.0),
            action: ScriptAction(language: .shell, script: "true")
        )

        XCTAssertThrowsError(try rule.validate(name: "testRule"))
    }

    func testConfigurationDefaultsMinimumForceDurationWhenMissing() throws {
        let configuration = try decodeConfiguration("""
        {
          "debugLogging": false,
          "gestures": {
            "threeFingerForcePress": {
              "fingerCount": 3,
              "minimumPressure": 0.88,
              "cooldownMilliseconds": 650,
              "region": null,
              "action": "doubleCommandTwice"
            },
            "upperRightForcePress": {
              "fingerCount": 1,
              "minimumPressure": 0.68,
              "cooldownMilliseconds": 900,
              "region": { "minX": 0.78, "maxX": 1.0, "minY": 0.72, "maxY": 1.0 },
              "action": "showAccessibilityKeyboard"
            }
          }
        }
        """)

        XCTAssertEqual(configuration.gestures.threeFingerForcePress.minimumForceMilliseconds, 45)
        XCTAssertEqual(configuration.gestures.upperLeftForcePress.name, "Top Left Force Touch 1")
        XCTAssertEqual(configuration.gestures.upperLeftForcePress.minimumPressure, TrackpadPressureThreshold.forceClick)
        XCTAssertTrue(configuration.gestures.upperLeftForcePress.requiresClick)
        XCTAssertEqual(configuration.gestures.upperLeftForcePress.action.script, DefaultScripts.placeholderAppleScript)
        XCTAssertEqual(configuration.gestures.leftEdgeTwoFingerSwipe.fingerCount, 2)
        XCTAssertEqual(configuration.gestures.leftEdgeTwoFingerSwipe.minimumTravel, 0.25)
        XCTAssertEqual(configuration.gestures.twoFingerHold.holdMilliseconds, 3_000)
        XCTAssertEqual(configuration.gestures.twoFingerHold.fingerCount, 2)
        XCTAssertEqual(configuration.gestures.upperRightForcePress.minimumForceMilliseconds, 45)
    }

    func testConfigurationDecodesScriptActions() throws {
        let configuration = try decodeConfiguration("""
        {
          "debugLogging": false,
          "gestures": {
            "threeFingerForcePress": {
              "fingerCount": 3,
              "minimumPressure": 0.88,
              "minimumForceMilliseconds": 45,
              "cooldownMilliseconds": 650,
              "requiresClick": true,
              "region": null,
              "action": {
                "language": "shell",
                "script": "echo force",
                "timeoutSeconds": 3
              }
            },
            "upperLeftForcePress": {
              "fingerCount": 1,
              "minimumPressure": 0.68,
              "minimumForceMilliseconds": 45,
              "cooldownMilliseconds": 650,
              "requiresClick": false,
              "region": { "minX": 0.0, "maxX": 0.22, "minY": 0.72, "maxY": 1.0 },
              "action": {
                "language": "appleScript",
                "script": "return left",
                "timeoutSeconds": 5
              }
            },
            "upperRightForcePress": {
              "fingerCount": 1,
              "minimumPressure": 0.68,
              "minimumForceMilliseconds": 45,
              "cooldownMilliseconds": 900,
              "requiresClick": false,
              "region": { "minX": 0.78, "maxX": 1.0, "minY": 0.72, "maxY": 1.0 },
              "action": {
                "language": "appleScript",
                "script": "return true",
                "timeoutSeconds": 5
              }
            }
          }
        }
        """)

        XCTAssertEqual(configuration.gestures.threeFingerForcePress.action.language, .shell)
        XCTAssertEqual(configuration.gestures.threeFingerForcePress.action.script, "echo force")
        XCTAssertEqual(configuration.gestures.upperLeftForcePress.action.script, "return left")
        XCTAssertEqual(configuration.gestures.leftEdgeTwoFingerSwipe.action.script, DefaultScripts.placeholderAppleScript)
        XCTAssertEqual(configuration.gestures.twoFingerHold.action.script, DefaultScripts.placeholderAppleScript)
        XCTAssertEqual(configuration.gestures.upperRightForcePress.action.language, .appleScript)
        XCTAssertEqual(configuration.gestures.upperRightForcePress.action.timeoutSeconds, 5)
    }

    func testConfigurationDecodesLeftEdgeSwipeActions() throws {
        let configuration = try decodeConfiguration("""
        {
          "debugLogging": false,
          "gestures": {
            "threeFingerForcePress": {
              "fingerCount": 3,
              "minimumPressure": 0.88,
              "cooldownMilliseconds": 650
            },
            "leftEdgeTwoFingerSwipe": {
              "fingerCount": 2,
              "edgeWidth": 0.12,
              "minimumTravel": 0.25,
              "cooldownMilliseconds": 650,
              "actions": [
                { "language": "shell", "script": "echo swipe", "timeoutSeconds": 3 }
              ]
            },
            "upperRightForcePress": {
              "fingerCount": 1,
              "minimumPressure": 0.86,
              "cooldownMilliseconds": 900,
              "requiresClick": true,
              "region": { "minX": 0.78, "maxX": 1.0, "minY": 0.72, "maxY": 1.0 }
            }
          }
        }
        """)

        XCTAssertEqual(configuration.gestures.leftEdgeTwoFingerSwipe.action.language, .shell)
        XCTAssertEqual(configuration.gestures.leftEdgeTwoFingerSwipe.action.script, "echo swipe")
    }

    func testConfigurationDecodesTwoFingerHoldActions() throws {
        let configuration = try decodeConfiguration("""
        {
          "debugLogging": false,
          "gestures": {
            "threeFingerForcePress": {
              "fingerCount": 3,
              "minimumPressure": 0.88,
              "cooldownMilliseconds": 650
            },
            "twoFingerHold": {
              "fingerCount": 2,
              "holdMilliseconds": 3000,
              "maximumMovement": 0.06,
              "cooldownMilliseconds": 1000,
              "region": { "minX": 0.2, "maxX": 0.8, "minY": 0.1, "maxY": 0.9 },
              "actions": [
                { "language": "shell", "script": "echo hold", "timeoutSeconds": 3 }
              ]
            },
            "upperRightForcePress": {
              "fingerCount": 1,
              "minimumPressure": 0.86,
              "cooldownMilliseconds": 900,
              "requiresClick": true,
              "region": { "minX": 0.78, "maxX": 1.0, "minY": 0.72, "maxY": 1.0 }
            }
          }
        }
        """)

        XCTAssertEqual(configuration.gestures.twoFingerHold.action.language, .shell)
        XCTAssertEqual(configuration.gestures.twoFingerHold.action.script, "echo hold")
        XCTAssertEqual(configuration.gestures.twoFingerHold.region?.minX, 0.2)
    }

    func testConfigurationDecodesOrderedScriptActions() throws {
        let configuration = try decodeConfiguration("""
        {
          "debugLogging": false,
          "gestures": {
            "threeFingerForcePress": {
              "fingerCount": 3,
              "minimumPressure": 0.88,
              "cooldownMilliseconds": 650,
              "actions": [
                { "language": "shell", "script": "echo first", "timeoutSeconds": 3 },
                { "name": "Double Command", "language": "appleScript", "script": "return true", "timeoutSeconds": 4 }
              ]
            },
            "upperRightForcePress": {
              "fingerCount": 1,
              "minimumPressure": 0.68,
              "cooldownMilliseconds": 900,
              "region": { "minX": 0.78, "maxX": 1.0, "minY": 0.72, "maxY": 1.0 },
              "actions": [
                { "language": "appleScript", "script": "return true", "timeoutSeconds": 5 }
              ]
            }
          }
        }
        """)

        XCTAssertEqual(configuration.gestures.threeFingerForcePress.actions.map(\.script), [
            "echo first",
            "return true"
        ])
        XCTAssertEqual(configuration.gestures.threeFingerForcePress.actions.map(\.name), [
            "Run Shell Script 1",
            "Double Command"
        ])
        XCTAssertEqual(configuration.gestures.threeFingerForcePress.actions[1].language, .appleScript)
    }

    func testConfigurationDecodesLatencyAction() throws {
        let configuration = try decodeConfiguration("""
        {
          "debugLogging": false,
          "gestures": {
            "threeFingerForcePress": {
              "fingerCount": 3,
              "minimumPressure": 0.88,
              "cooldownMilliseconds": 650,
              "actions": [
                { "language": "shell", "script": "echo first" },
                { "type": "latency", "durationMilliseconds": 1250 },
                { "language": "shell", "script": "echo second" }
              ]
            }
          }
        }
        """)

        let actions = configuration.gestures.threeFingerForcePress.actions
        XCTAssertEqual(actions[1].typeDisplayName, LatencyAction.displayName)
        XCTAssertEqual(actions[1].name, "Action Latency 2")
        XCTAssertEqual(actions[1].latencyAction?.durationMilliseconds, 1_250)
    }

    func testConfigurationAllowsEmptyActionList() throws {
        var rule = AppConfiguration.default.gestures.threeFingerForcePress
        rule.actions = []

        XCTAssertNoThrow(try rule.validate(name: "threeFingerForcePress"))
        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(PressGestureRule.self, from: data)
        XCTAssertTrue(decoded.actions.isEmpty)
    }

    private func decodeConfiguration(_ json: String) throws -> AppConfiguration {
        try JSONDecoder().decode(AppConfiguration.self, from: Data(json.utf8))
    }
}
