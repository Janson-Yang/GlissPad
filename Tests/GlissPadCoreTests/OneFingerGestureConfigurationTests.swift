@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerGestureConfigurationTests: XCTestCase {
    func testDecodesOneFingerTouchStartTrigger() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.touchStartJSON.utf8))

        XCTAssertEqual(configuration.gestures.triggers.first?.type, .oneFingerTouchStart)
        XCTAssertEqual(configuration.gestures.oneFingerTouchStart.name, "One Finger Touch Start")
        XCTAssertEqual(configuration.gestures.oneFingerTouchStart.action.script, "echo touch")
        XCTAssertNoThrow(try configuration.validate())
    }

    func testDecodesOneFingerLongPressTrigger() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.longPressJSON.utf8))

        XCTAssertEqual(configuration.gestures.triggers.first?.type, .oneFingerLongPress)
        XCTAssertEqual(configuration.gestures.oneFingerLongPress.fingerCount, 1)
        XCTAssertEqual(configuration.gestures.oneFingerLongPress.holdMilliseconds, 800)
        XCTAssertNoThrow(try configuration.validate())
    }

    func testDecodesOneFingerCircleTrigger() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.circleJSON.utf8))

        XCTAssertEqual(configuration.gestures.triggers.first?.type, .oneFingerCircle)
        XCTAssertEqual(configuration.gestures.oneFingerCircle.direction, .counterclockwise)
        XCTAssertEqual(configuration.gestures.oneFingerCircle.action.script, "echo circle")
        XCTAssertNoThrow(try configuration.validate())
    }

    func testDecodesOneFingerCornerClickTrigger() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.cornerClickJSON.utf8))

        XCTAssertEqual(configuration.gestures.triggers.first?.type, .oneFingerCornerClick)
        XCTAssertEqual(configuration.gestures.oneFingerCornerClick.corner, .lowerLeft)
        XCTAssertEqual(configuration.gestures.oneFingerCornerClick.clickKind, .tap)
        XCTAssertEqual(configuration.gestures.oneFingerCornerClick.region.maxY, 0.3)
        XCTAssertNoThrow(try configuration.validate())
    }

    func testDecodesOneFingerTapTriggers() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.tapJSON.utf8))

        XCTAssertEqual(configuration.gestures.triggers.map(\.type), [.oneFingerTap, .oneFingerDoubleTap])
        XCTAssertEqual(configuration.gestures.oneFingerTap.tapCount, 1)
        XCTAssertEqual(configuration.gestures.oneFingerDoubleTap.tapCount, 2)
        XCTAssertNoThrow(try configuration.validate())
    }

    func testDefaultConfigurationDoesNotEnableTouchStart() {
        XCTAssertFalse(AppConfiguration.default.gestures.triggers.contains { $0.type == .oneFingerTouchStart })
        XCTAssertFalse(AppConfiguration.default.gestures.triggers.contains { $0.type == .oneFingerLongPress })
        XCTAssertFalse(AppConfiguration.default.gestures.triggers.contains { $0.type == .oneFingerCircle })
        XCTAssertFalse(AppConfiguration.default.gestures.triggers.contains { $0.type == .oneFingerCornerClick })
        XCTAssertFalse(AppConfiguration.default.gestures.triggers.contains { $0.type == .oneFingerTap })
        XCTAssertFalse(AppConfiguration.default.gestures.triggers.contains { $0.type == .oneFingerDoubleTap })
    }

    func testRejectsInvalidCooldown() {
        XCTAssertThrowsError(
            try OneFingerGestureRule(
                name: "Touch Start",
                isEnabled: true,
                cooldownMilliseconds: 99,
                actions: []
            ).validate(name: "oneFinger")
        )
    }

    private static let touchStartJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "touch-start",
            "type": "oneFingerTouchStart",
            "oneFinger": {
              "name": "One Finger Touch Start",
              "isEnabled": true,
              "cooldownMilliseconds": 650,
              "actions": [
                { "language": "shell", "script": "echo touch", "timeoutSeconds": 3 }
              ]
            }
          }
        ]
      }
    }
    """

    private static let longPressJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "long-press",
            "type": "oneFingerLongPress",
            "hold": {
              "name": "Long Press",
              "isEnabled": true,
              "fingerCount": 1,
              "holdMilliseconds": 800,
              "maximumMovement": 0.04,
              "cooldownMilliseconds": 650,
              "actions": []
            }
          }
        ]
      }
    }
    """

    private static let circleJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "circle",
            "type": "oneFingerCircle",
            "circle": {
              "name": "Circle",
              "isEnabled": true,
              "direction": "counterclockwise",
              "cooldownMilliseconds": 650,
              "minimumRadius": 0.08,
              "minimumRotationRadians": 5.2,
              "actions": [
                { "language": "shell", "script": "echo circle", "timeoutSeconds": 3 }
              ]
            }
          }
        ]
      }
    }
    """

    private static let cornerClickJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "corner-click",
            "type": "oneFingerCornerClick",
            "cornerClick": {
              "name": "Corner Tap",
              "isEnabled": true,
              "corner": "lowerLeft",
              "clickKind": "tap",
              "minimumPressure": 0.86,
              "minimumForceMilliseconds": 45,
              "maximumMovement": 0.045,
              "cooldownMilliseconds": 650,
              "region": { "minX": 0, "maxX": 0.25, "minY": 0, "maxY": 0.3 },
              "actions": []
            }
          }
        ]
      }
    }
    """

    private static let tapJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "tap",
            "type": "oneFingerTap",
            "tap": {
              "name": "Tap",
              "isEnabled": true,
              "tapCount": 1,
              "maximumTapMilliseconds": 250,
              "doubleTapMaximumIntervalMilliseconds": 350,
              "maximumMovement": 0.045,
              "cooldownMilliseconds": 650,
              "actions": []
            }
          },
          {
            "id": "double-tap",
            "type": "oneFingerDoubleTap",
            "tap": {
              "name": "Double Tap",
              "isEnabled": true,
              "tapCount": 2,
              "maximumTapMilliseconds": 250,
              "doubleTapMaximumIntervalMilliseconds": 350,
              "maximumMovement": 0.045,
              "cooldownMilliseconds": 650,
              "actions": []
            }
          }
        ]
      }
    }
    """
}
