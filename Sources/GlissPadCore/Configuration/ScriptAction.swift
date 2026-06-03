import Foundation

public struct ScriptAction: Codable, Equatable, Sendable {
    public static let displayName = "Run AppleScript"

    public var name: String
    public var language: ScriptLanguage
    public var script: String
    public var timeoutSeconds: TimeInterval

    enum CodingKeys: String, CodingKey {
        case name
        case language
        case script
        case timeoutSeconds
    }

    public init(
        name: String = "",
        language: ScriptLanguage,
        script: String,
        timeoutSeconds: TimeInterval = 5
    ) {
        self.name = name
        self.language = language
        self.script = script
        self.timeoutSeconds = timeoutSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        language = try container.decode(ScriptLanguage.self, forKey: .language)
        script = try container.decode(String.self, forKey: .script)
        timeoutSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .timeoutSeconds) ?? 5
    }

    public func defaultNamed(index: Int) -> ScriptAction {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return self }
        var action = self
        action.name = "\(language.displayName) \(index + 1)"
        return action
    }

    func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).script must not be empty.")
        }
        guard (0.1...60).contains(timeoutSeconds) else {
            throw ConfigurationError.invalidValue("\(name).timeoutSeconds must be 0.1...60.")
        }
    }
}

public enum ScriptLanguage: String, CaseIterable, Codable, Equatable, Sendable {
    case shell
    case appleScript

    public var displayName: String {
        switch self {
        case .shell:
            return "Run Shell Script"
        case .appleScript:
            return "Run AppleScript"
        }
    }

    var executablePath: String {
        switch self {
        case .shell:
            return "/bin/bash"
        case .appleScript:
            return "/usr/bin/osascript"
        }
    }

    func arguments(for script: String) -> [String] {
        switch self {
        case .shell:
            return ["-lc", script]
        case .appleScript:
            return ["-e", script]
        }
    }
}
