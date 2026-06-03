import Foundation

public struct CircleGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var direction: CircleDirection
    public var cooldownMilliseconds: Int
    public var minimumRadius: Double
    public var minimumRotationRadians: Double
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
        case direction
        case cooldownMilliseconds
        case minimumRadius
        case minimumRotationRadians
        case action
        case actions
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        direction: CircleDirection,
        cooldownMilliseconds: Int,
        minimumRadius: Double = 0.08,
        minimumRotationRadians: Double = Double.pi * 1.65,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.direction = direction
        self.cooldownMilliseconds = cooldownMilliseconds
        self.minimumRadius = minimumRadius
        self.minimumRotationRadians = minimumRotationRadians
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        direction: CircleDirection,
        cooldownMilliseconds: Int,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            direction: direction,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: GestureActionsCoding.scriptActions([action])
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        direction = try container.decodeIfPresent(CircleDirection.self, forKey: .direction) ?? .clockwise
        cooldownMilliseconds = try container.decodeIfPresent(Int.self, forKey: .cooldownMilliseconds) ?? 650
        minimumRadius = try container.decodeIfPresent(Double.self, forKey: .minimumRadius) ?? 0.08
        minimumRotationRadians = try container.decodeIfPresent(
            Double.self,
            forKey: .minimumRotationRadians
        ) ?? Double.pi * 1.65
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
        try container.encode(direction, forKey: .direction)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encode(minimumRadius, forKey: .minimumRadius)
        try container.encode(minimumRotationRadians, forKey: .minimumRotationRadians)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        guard (0.02...0.4).contains(minimumRadius) else {
            throw ConfigurationError.invalidValue("\(name).minimumRadius must be 0.02...0.4.")
        }
        guard (Double.pi...Double.pi * 2.2).contains(minimumRotationRadians) else {
            throw ConfigurationError.invalidValue("\(name).minimumRotationRadians must be pi...2.2pi.")
        }
        for (index, action) in actions.enumerated() {
            try action.validate(name: "\(name).actions[\(index)]")
        }
    }
}

public enum CircleDirection: String, CaseIterable, Codable, Equatable, Sendable {
    case clockwise
    case counterclockwise

    public var displayName: String {
        switch self {
        case .clockwise: return "Clockwise"
        case .counterclockwise: return "Counterclockwise"
        }
    }
}
