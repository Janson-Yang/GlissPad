import Foundation

public struct TouchStartGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var fingerCount: Int
    public var cooldownMilliseconds: Int
    public var region: NormalizedRegion?
    public var actions: [GestureAction]

    enum CodingKeys: String, CodingKey {
        case name, isEnabled, fingerCount, cooldownMilliseconds, region, action, actions
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.fingerCount = fingerCount
        self.cooldownMilliseconds = cooldownMilliseconds
        self.region = region
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            fingerCount: fingerCount,
            cooldownMilliseconds: cooldownMilliseconds,
            region: region,
            actions: GestureActionsCoding.scriptActions([action])
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        fingerCount = try container.decode(Int.self, forKey: .fingerCount)
        cooldownMilliseconds = try container.decodeIfPresent(Int.self, forKey: .cooldownMilliseconds) ?? 650
        region = try container.decodeIfPresent(NormalizedRegion.self, forKey: .region)
        actions = try GestureActionsCoding.decode(from: container, actionKey: .action, actionsKey: .actions) { _ in
            ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(fingerCount, forKey: .fingerCount)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (1...5).contains(fingerCount) else {
            throw ConfigurationError.invalidValue("\(name).fingerCount must be between 1 and 5.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try region?.validate(name: "\(name).region")
        try actions.enumerated().forEach { try $0.element.validate(name: "\(name).actions[\($0.offset)]") }
    }
}
