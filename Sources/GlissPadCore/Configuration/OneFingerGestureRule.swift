import Foundation

public struct OneFingerGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var cooldownMilliseconds: Int
    public var region: NormalizedRegion?
    public var actions: [GestureAction]

    public var action: ScriptAction {
        get {
            actions.compactMap(\.scriptAction).first
                ?? ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
        set { actions = GestureActionsCoding.scriptActions([newValue]) }
    }

    enum CodingKeys: String, CodingKey {
        case name
        case isEnabled
        case cooldownMilliseconds
        case region
        case action
        case actions
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.cooldownMilliseconds = cooldownMilliseconds
        self.region = region
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            cooldownMilliseconds: cooldownMilliseconds,
            region: region,
            actions: GestureActionsCoding.scriptActions([action])
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        cooldownMilliseconds = try container.decodeIfPresent(Int.self, forKey: .cooldownMilliseconds) ?? 650
        region = try container.decodeIfPresent(NormalizedRegion.self, forKey: .region)
        actions = try GestureActionsCoding.decode(
            from: container,
            actionKey: .action,
            actionsKey: .actions
        ) { _ in
            ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try region?.validate(name: "\(name).region")
        for (index, action) in actions.enumerated() {
            try action.validate(name: "\(name).actions[\(index)]")
        }
    }
}
