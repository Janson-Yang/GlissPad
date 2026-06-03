import Foundation

public struct ReleaseGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var previousFingerCount: ReleaseFingerCount
    public var releaseToleranceMilliseconds: Int
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
        case name
        case isEnabled
        case previousFingerCount
        case releaseToleranceMilliseconds
        case cooldownMilliseconds
        case action
        case actions
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        previousFingerCount: ReleaseFingerCount,
        releaseToleranceMilliseconds: Int = 200,
        cooldownMilliseconds: Int,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.previousFingerCount = previousFingerCount
        self.releaseToleranceMilliseconds = releaseToleranceMilliseconds
        self.cooldownMilliseconds = cooldownMilliseconds
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        previousFingerCount: ReleaseFingerCount,
        releaseToleranceMilliseconds: Int = 200,
        cooldownMilliseconds: Int,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            previousFingerCount: previousFingerCount,
            releaseToleranceMilliseconds: releaseToleranceMilliseconds,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: GestureActionsCoding.scriptActions([action])
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        previousFingerCount = try container.decodeIfPresent(
            ReleaseFingerCount.self,
            forKey: .previousFingerCount
        ) ?? .any
        releaseToleranceMilliseconds = try container.decodeIfPresent(
            Int.self,
            forKey: .releaseToleranceMilliseconds
        ) ?? 200
        cooldownMilliseconds = try container.decodeIfPresent(Int.self, forKey: .cooldownMilliseconds) ?? 650
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
        try container.encode(previousFingerCount, forKey: .previousFingerCount)
        try container.encode(releaseToleranceMilliseconds, forKey: .releaseToleranceMilliseconds)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        guard (0...1_000).contains(releaseToleranceMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).releaseToleranceMilliseconds must be 0...1000.")
        }
        for (index, action) in actions.enumerated() {
            try action.validate(name: "\(name).actions[\(index)]")
        }
    }
}

public enum ReleaseFingerCount: Codable, Equatable, Sendable {
    case any
    case exact(Int)

    public var displayName: String {
        switch self {
        case .any: return "Any"
        case .exact(let count): return "\(count) Finger\(count == 1 ? "" : "s")"
        }
    }

    public func matches(_ count: Int) -> Bool {
        switch self {
        case .any: return (1...5).contains(count)
        case .exact(let expected): return expected == count
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self), text == "any" {
            self = .any
            return
        }
        let count = try container.decode(Int.self)
        guard (1...5).contains(count) else {
            throw ConfigurationError.invalidValue("previousFingerCount must be 1...5 or any.")
        }
        self = .exact(count)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .any:
            try container.encode("any")
        case .exact(let count):
            try container.encode(count)
        }
    }
}

public extension ReleaseFingerCount {
    static let menuOptions: [ReleaseFingerCount] = [.any, .exact(1), .exact(2), .exact(3), .exact(4), .exact(5)]
}
