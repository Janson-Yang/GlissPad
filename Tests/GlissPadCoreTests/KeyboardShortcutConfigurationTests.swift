@testable import GlissPadCore
import Foundation
import XCTest

final class KeyboardShortcutConfigurationTests: XCTestCase {
    func testConfigurationDecodesKeyboardShortcutAction() throws {
        let configuration = try decodeConfiguration("""
        {
          "debugLogging": false,
          "gestures": {
            "threeFingerForcePress": {
              "fingerCount": 3,
              "minimumPressure": 0.88,
              "cooldownMilliseconds": 650,
              "actions": [
                {
                  "type": "keyboardShortcut",
                  "name": "Command A",
                  "mode": "keyCombination",
                  "primaryKey": "command",
                  "secondaryKey": "a"
                }
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

        guard case .keyboardShortcut(let action) = configuration.gestures.threeFingerForcePress.actions.first else {
            XCTFail("Expected keyboard shortcut action")
            return
        }
        XCTAssertEqual(action.name, "Command A")
        XCTAssertEqual(action.mode, .keyCombination)
        XCTAssertEqual(action.primaryKey.keyCode, 55)
        XCTAssertEqual(action.secondaryKey?.keyCode, 0)
        XCTAssertEqual(action.keyHoldMilliseconds, KeyboardShortcutAction.defaultKeyHoldMilliseconds)
        XCTAssertEqual(
            action.postReleaseDelayMilliseconds,
            KeyboardShortcutAction.defaultPostReleaseDelayMilliseconds
        )
    }

    func testConfigurationDecodesCapturedKeyCodes() throws {
        let configuration = try decodeConfiguration("""
        {
          "debugLogging": false,
          "gestures": {
            "threeFingerForcePress": {
              "fingerCount": 3,
              "minimumPressure": 0.88,
              "cooldownMilliseconds": 650,
              "actions": [
                {
                  "type": "keyboardShortcut",
                  "name": "Right Command F1",
                  "mode": "keyCombination",
                  "primaryKey": { "keyCode": 54, "displayName": "Right Command" },
                  "secondaryKey": { "keyCode": 122, "displayName": "F1" }
                }
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

        guard case .keyboardShortcut(let action) = configuration.gestures.threeFingerForcePress.actions.first else {
            XCTFail("Expected keyboard shortcut action")
            return
        }
        XCTAssertEqual(action.primaryKey, KeyboardKey(keyCode: 54, displayName: "Right Command"))
        XCTAssertEqual(action.secondaryKey, KeyboardKey(keyCode: 122, displayName: "F1"))
    }

    func testKeyboardShortcutTimingRoundTripsThroughGestureAction() throws {
        let action = GestureAction.keyboardShortcut(KeyboardShortcutAction(
            name: "Double Command Tap",
            mode: .singleKey,
            primaryKey: .leftCommand,
            keyHoldMilliseconds: 40,
            postReleaseDelayMilliseconds: 180
        ))

        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(GestureAction.self, from: data)

        XCTAssertEqual(decoded.keyboardShortcutAction?.keyHoldMilliseconds, 40)
        XCTAssertEqual(decoded.keyboardShortcutAction?.postReleaseDelayMilliseconds, 180)
    }

    func testKeyboardShortcutCombinationRequiresSecondKey() {
        let action = KeyboardShortcutAction(
            name: "Broken Shortcut",
            mode: .keyCombination,
            primaryKey: .command
        )

        XCTAssertThrowsError(try action.validate(name: "action"))
    }

    func testKeyboardShortcutCombinationRejectsRepeatedKey() {
        let action = KeyboardShortcutAction(
            name: "Broken Shortcut",
            mode: .keyCombination,
            primaryKey: .command,
            secondaryKey: .command
        )

        XCTAssertThrowsError(try action.validate(name: "action"))
    }

    func testKeyboardShortcutRejectsInvalidTiming() {
        let invalidHold = KeyboardShortcutAction(
            name: "Broken Hold",
            mode: .singleKey,
            primaryKey: .command,
            keyHoldMilliseconds: 0
        )
        let invalidDelay = KeyboardShortcutAction(
            name: "Broken Delay",
            mode: .singleKey,
            primaryKey: .command,
            postReleaseDelayMilliseconds: -1
        )

        XCTAssertThrowsError(try invalidHold.validate(name: "action"))
        XCTAssertThrowsError(try invalidDelay.validate(name: "action"))
    }

    func testAppleScriptUsesCapturedFunctionKeyCode() {
        let key = KeyboardKey(keyCode: 122, displayName: "F1")

        XCTAssertEqual(
            KeyboardShortcutAppleScript.script(for: [key]),
            "tell application \"System Events\" to key code 122"
        )
    }

    func testAppleScriptUsesGenericModifierForShortcut() {
        let script = KeyboardShortcutAppleScript.script(for: [.leftCommand, .a])

        XCTAssertEqual(
            script,
            "tell application \"System Events\" to key code 0 using {command down}"
        )
    }

    func testAppleScriptRejectsTwoRegularKeys() {
        XCTAssertNil(KeyboardShortcutAppleScript.script(for: [.a, KeyboardKey(keyCode: 11)]))
    }

    private func decodeConfiguration(_ json: String) throws -> AppConfiguration {
        try JSONDecoder().decode(AppConfiguration.self, from: Data(json.utf8))
    }
}
