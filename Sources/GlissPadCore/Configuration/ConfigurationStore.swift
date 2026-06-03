import Foundation

public final class ConfigurationStore: Sendable {
    public let configurationURL: URL
    private let legacyConfigurationURLs: [URL]

    public init(configurationURL: URL = ConfigurationStore.defaultConfigurationURL()) {
        self.configurationURL = configurationURL
        legacyConfigurationURLs = []
    }

    init(configurationURL: URL, legacyConfigurationURL: URL?) {
        self.configurationURL = configurationURL
        legacyConfigurationURLs = legacyConfigurationURL.map { [$0] } ?? []
    }

    init(configurationURL: URL, legacyConfigurationURLs: [URL]) {
        self.configurationURL = configurationURL
        self.legacyConfigurationURLs = legacyConfigurationURLs
    }

    var usesLegacyConfigurationMigration: Bool {
        !legacyConfigurationURLs.isEmpty
    }

    public func loadOrCreate() throws -> AppConfiguration {
        try migrateDefaultConfigurationIfNeeded()
        if FileManager.default.fileExists(atPath: configurationURL.path) {
            let loaded = try AppConfiguration.load(path: configurationURL.path)
            let migrated = loaded.replacingBundledDefaultScripts()
            if migrated != loaded {
                try save(migrated)
            }
            return migrated
        }
        let configuration = AppConfiguration.default
        try save(configuration)
        return configuration
    }

    public func save(_ configuration: AppConfiguration) throws {
        try configuration.validate()
        try FileManager.default.createDirectory(
            at: configurationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(configuration).write(to: configurationURL, options: .atomic)
    }

    public static func defaultConfigurationURL() -> URL {
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/GlissPad", isDirectory: true)
        return directory.appendingPathComponent("config.json")
    }

    private func migrateDefaultConfigurationIfNeeded() throws {
        guard !FileManager.default.fileExists(atPath: configurationURL.path),
              let sourceURL = legacyConfigurationURLs.first(where: {
                  FileManager.default.fileExists(atPath: $0.path)
              }) else {
            return
        }
        try FileManager.default.createDirectory(
            at: configurationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(
            at: sourceURL,
            to: configurationURL
        )
    }

}
