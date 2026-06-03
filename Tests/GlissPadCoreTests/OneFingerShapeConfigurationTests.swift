@testable import GlissPadCore
import Foundation
import XCTest

final class OneFingerShapeConfigurationTests: XCTestCase {
    func testDecodesSquareTrigger() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.squareJSON.utf8))

        XCTAssertEqual(configuration.gestures.triggers.first?.type, .oneFingerSquare)
        XCTAssertEqual(configuration.gestures.oneFingerSquare.shape, .square)
        XCTAssertEqual(configuration.gestures.oneFingerSquare.action.script, "echo square")
        XCTAssertNoThrow(try configuration.validate())
    }

    func testDecodesTriangleTrigger() throws {
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: Data(Self.triangleJSON.utf8))

        XCTAssertEqual(configuration.gestures.triggers.first?.type, .oneFingerTriangle)
        XCTAssertEqual(configuration.gestures.oneFingerTriangle.shape, .triangle)
        XCTAssertEqual(configuration.gestures.oneFingerTriangle.cornerTolerance, 0.12)
        XCTAssertNoThrow(try configuration.validate())
    }

    private static let squareJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "square",
            "type": "oneFingerSquare",
            "shape": {
              "name": "Square",
              "isEnabled": true,
              "shape": "square",
              "cornerTolerance": 0.14,
              "minimumSize": 0.12,
              "cooldownMilliseconds": 650,
              "actions": [
                { "language": "shell", "script": "echo square", "timeoutSeconds": 3 }
              ]
            }
          }
        ]
      }
    }
    """

    private static let triangleJSON = """
    {
      "debugLogging": false,
      "gestures": {
        "triggers": [
          {
            "id": "triangle",
            "type": "oneFingerTriangle",
            "shape": {
              "name": "Triangle",
              "isEnabled": true,
              "shape": "triangle",
              "cornerTolerance": 0.12,
              "minimumSize": 0.12,
              "cooldownMilliseconds": 650,
              "actions": []
            }
          }
        ]
      }
    }
    """
}
