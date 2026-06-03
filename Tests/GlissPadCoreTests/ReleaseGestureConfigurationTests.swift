@testable import GlissPadCore
import Foundation
import XCTest

final class ReleaseGestureConfigurationTests: XCTestCase {
    func testDecodesReleaseLastFingerTrigger() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.releaseJSON.utf8))

        XCTAssertEqual(configuration.gestures.triggers.first?.type, .releaseLastFinger)
        XCTAssertEqual(configuration.gestures.releaseLastFinger.previousFingerCount, .any)
        XCTAssertEqual(configuration.gestures.releaseLastFinger.releaseToleranceMilliseconds, 180)
        XCTAssertEqual(configuration.gestures.releaseLastFinger.action.script, "echo release")
        XCTAssertNoThrow(try configuration.validate())
    }

    func testDefaultsReleaseToleranceWhenMissing() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.legacyReleaseJSON.utf8))

        XCTAssertEqual(configuration.gestures.releaseLastFinger.releaseToleranceMilliseconds, 200)
        XCTAssertNoThrow(try configuration.validate())
    }

    func testRejectsInvalidReleaseTolerance() {
        XCTAssertThrowsError(
            try ReleaseGestureRule(
                name: "Release Last Finger",
                isEnabled: true,
                previousFingerCount: .any,
                releaseToleranceMilliseconds: 1_001,
                cooldownMilliseconds: 650,
                actions: []
            ).validate(name: "release")
        )
    }

    func testFingerCountRejectsOutOfRangeValues() {
        XCTAssertThrowsError(
            try JSONDecoder().decode(ReleaseFingerCount.self, from: Data("6".utf8))
        )
    }

    func testDefaultConfigurationDoesNotEnableReleaseOnEveryLift() {
        XCTAssertFalse(AppConfiguration.default.gestures.triggers.contains { $0.type == .releaseLastFinger })
    }

    private static let releaseJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "release-any",
            "type": "releaseLastFinger",
            "release": {
              "name": "Release Last Finger",
              "isEnabled": true,
              "previousFingerCount": "any",
              "releaseToleranceMilliseconds": 180,
              "cooldownMilliseconds": 650,
              "actions": [
                { "language": "shell", "script": "echo release", "timeoutSeconds": 3 }
              ]
            }
          }
        ]
      }
    }
    """

    private static let legacyReleaseJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "release-any",
            "type": "releaseLastFinger",
            "release": {
              "name": "Release Last Finger",
              "isEnabled": true,
              "previousFingerCount": "any",
              "cooldownMilliseconds": 650,
              "actions": []
            }
          }
        ]
      }
    }
    """
}
