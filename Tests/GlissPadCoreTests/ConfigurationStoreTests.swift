@testable import GlissPadCore
import XCTest

final class ConfigurationStoreTests: XCTestCase {
    func testDefaultStoreDoesNotReadLegacyConfigurationSources() {
        let store = ConfigurationStore()

        XCTAssertFalse(store.usesLegacyConfigurationMigration)
    }

    func testLoadOrCreateWritesEmptyConfigurationWhenCurrentFileIsMissing() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let currentURL = rootURL.appendingPathComponent("GlissPad/config.json")
        let store = ConfigurationStore(configurationURL: currentURL)

        let configuration = try store.loadOrCreate()
        let savedData = try Data(contentsOf: currentURL)
        let savedConfiguration = try JSONDecoder().decode(AppConfiguration.self, from: savedData)

        XCTAssertTrue(configuration.gestures.triggers.isEmpty)
        XCTAssertEqual(savedConfiguration, configuration)
    }

    func testLoadOrCreateMigratesLegacyConfigurationWhenCurrentFileIsMissing() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let legacyURL = rootURL.appendingPathComponent("Legacy/config.json")
        let currentURL = rootURL.appendingPathComponent("GlissPad/config.json")
        let expectedConfiguration = AppConfiguration.default

        try FileManager.default.createDirectory(
            at: legacyURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(expectedConfiguration).write(to: legacyURL)

        let store = ConfigurationStore(
            configurationURL: currentURL,
            legacyConfigurationURL: legacyURL
        )
        let migratedConfiguration = try store.loadOrCreate()

        XCTAssertEqual(migratedConfiguration, expectedConfiguration)
        XCTAssertTrue(FileManager.default.fileExists(atPath: currentURL.path))
    }

    func testLoadOrCreatePrefersFirstAvailableLegacyConfiguration() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let currentURL = rootURL.appendingPathComponent("GlissPad/config.json")
        let olderLegacyURL = rootURL.appendingPathComponent("Older/config.json")
        let newerLegacyURL = rootURL.appendingPathComponent("Newer/config.json")
        let expectedConfiguration = AppConfiguration.default
        let olderConfiguration = AppConfiguration(gestures: .default, debugLogging: true)

        try write(olderConfiguration, to: olderLegacyURL)
        try write(expectedConfiguration, to: newerLegacyURL)

        let store = ConfigurationStore(
            configurationURL: currentURL,
            legacyConfigurationURLs: [newerLegacyURL, olderLegacyURL]
        )

        XCTAssertEqual(try store.loadOrCreate(), expectedConfiguration)
    }

    private func write(_ configuration: AppConfiguration, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(configuration).write(to: url)
    }
}
