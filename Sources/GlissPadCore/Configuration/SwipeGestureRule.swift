import Foundation

public struct SwipeGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var fingerCount: Int
    public var edgeWidth: Double
    public var minimumTravel: Double
    public var cooldownMilliseconds: Int
    public var actions: [GestureAction]

    public var action: ScriptAction {
        get {
            actions.first?.scriptAction
                ?? ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
        set { actions = GestureActionsCoding.scriptActions([newValue]) }
    }

    enum CodingKeys: String, CodingKey {
        case name
        case isEnabled
        case fingerCount
        case edgeWidth
        case minimumTravel
        case cooldownMilliseconds
        case action
        case actions
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int,
        edgeWidth: Double,
        minimumTravel: Double,
        cooldownMilliseconds: Int,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.fingerCount = fingerCount
        self.edgeWidth = edgeWidth
        self.minimumTravel = minimumTravel
        self.cooldownMilliseconds = cooldownMilliseconds
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int,
        edgeWidth: Double,
        minimumTravel: Double,
        cooldownMilliseconds: Int,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            fingerCount: fingerCount,
            edgeWidth: edgeWidth,
            minimumTravel: minimumTravel,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: [.script(action)]
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        fingerCount = try container.decode(Int.self, forKey: .fingerCount)
        edgeWidth = try container.decode(Double.self, forKey: .edgeWidth)
        minimumTravel = try container.decode(Double.self, forKey: .minimumTravel)
        cooldownMilliseconds = try container.decode(Int.self, forKey: .cooldownMilliseconds)
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
        try container.encode(fingerCount, forKey: .fingerCount)
        try container.encode(edgeWidth, forKey: .edgeWidth)
        try container.encode(minimumTravel, forKey: .minimumTravel)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (1...5).contains(fingerCount) else {
            throw ConfigurationError.invalidValue("\(name).fingerCount must be between 1 and 5.")
        }
        guard (0.01...0.35).contains(edgeWidth) else {
            throw ConfigurationError.invalidValue("\(name).edgeWidth must be between 0.01 and 0.35.")
        }
        guard (0.05...1.0).contains(minimumTravel) else {
            throw ConfigurationError.invalidValue("\(name).minimumTravel must be between 0.05 and 1.0.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        for (index, action) in actions.enumerated() {
            try action.validate(name: "\(name).actions[\(index)]")
        }
    }
}
