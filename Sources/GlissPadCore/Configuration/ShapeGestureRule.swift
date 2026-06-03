import Foundation

public struct ShapeGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var shape: ShapeGestureKind
    public var cornerTolerance: Double
    public var minimumSize: Double
    public var cooldownMilliseconds: Int
    public var actions: [GestureAction]

    public var action: ScriptAction {
        get {
            actions.compactMap(\.scriptAction).first
                ?? ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
        set { actions = GestureActionsCoding.scriptActions([newValue]) }
    }

    enum CodingKeys: String, CodingKey {
        case name, isEnabled, shape, cornerTolerance, minimumSize, cooldownMilliseconds, action, actions
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        shape: ShapeGestureKind,
        cornerTolerance: Double = 0.14,
        minimumSize: Double = 0.12,
        cooldownMilliseconds: Int,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.shape = shape
        self.cornerTolerance = cornerTolerance
        self.minimumSize = minimumSize
        self.cooldownMilliseconds = cooldownMilliseconds
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        shape: ShapeGestureKind,
        cooldownMilliseconds: Int,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            shape: shape,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: GestureActionsCoding.scriptActions([action])
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        shape = try container.decodeIfPresent(ShapeGestureKind.self, forKey: .shape) ?? .square
        cornerTolerance = try container.decodeIfPresent(Double.self, forKey: .cornerTolerance) ?? 0.14
        minimumSize = try container.decodeIfPresent(Double.self, forKey: .minimumSize) ?? 0.12
        cooldownMilliseconds = try container.decodeIfPresent(Int.self, forKey: .cooldownMilliseconds) ?? 650
        actions = try GestureActionsCoding.decode(from: container, actionKey: .action, actionsKey: .actions) { _ in
            ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(shape, forKey: .shape)
        try container.encode(cornerTolerance, forKey: .cornerTolerance)
        try container.encode(minimumSize, forKey: .minimumSize)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (0.05...0.3).contains(cornerTolerance) else {
            throw ConfigurationError.invalidValue("\(name).cornerTolerance must be 0.05...0.3.")
        }
        guard (0.05...0.5).contains(minimumSize) else {
            throw ConfigurationError.invalidValue("\(name).minimumSize must be 0.05...0.5.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try actions.enumerated().forEach { try $0.element.validate(name: "\(name).actions[\($0.offset)]") }
    }
}

public enum ShapeGestureKind: String, Codable, Equatable, Sendable {
    case square
    case triangle

    var cornerCount: Int {
        switch self {
        case .square: return 4
        case .triangle: return 3
        }
    }
}
