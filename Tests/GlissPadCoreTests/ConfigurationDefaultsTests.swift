@testable import GlissPadCore
import Foundation
import XCTest

final class ConfigurationDefaultsTests: XCTestCase {
    func testDefaultConfigurationStartsEmpty() {
        XCTAssertFalse(AppConfiguration.default.debugLogging)
        XCTAssertTrue(AppConfiguration.default.gestures.triggers.isEmpty)
    }

    func testExampleConfigurationDecodesAndValidates() throws {
        let configuration = try JSONDecoder().decode(
            AppConfiguration.self,
            from: try Data(contentsOf: projectRootURL.appendingPathComponent("config.example.json"))
        )

        XCTAssertNoThrow(try configuration.validate())
    }

    private var projectRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
