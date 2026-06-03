import Foundation

public struct TwoFingerTransformGestureRule: Codable, Equatable, Sendable {
    public static let defaultMinimumScaleChange = 0.08
    public static let defaultMinimumRotationDegrees = 8.0

    public var name: String
    public var isEnabled: Bool
    public var minimumScaleChange: Double
    public var minimumRotationDegrees: Double
    public var cooldownMilliseconds: Int
    public var region: NormalizedRegion?
    public var actions: [GestureAction]

    enum CodingKeys: String, CodingKey {
        case name, isEnabled, minimumScaleChange, minimumRotationDegrees
        case cooldownMilliseconds, region, action, actions
    }

    public init(
        name: String,
        isEnabled: Bool,
        minimumScaleChange: Double = Self.defaultMinimumScaleChange,
        minimumRotationDegrees: Double = Self.defaultMinimumRotationDegrees,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.minimumScaleChange = minimumScaleChange
        self.minimumRotationDegrees = minimumRotationDegrees
        self.cooldownMilliseconds = cooldownMilliseconds
        self.region = region
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        minimumScaleChange = try container.decodeIfPresent(
            Double.self,
            forKey: .minimumScaleChange
        ) ?? Self.defaultMinimumScaleChange
        minimumRotationDegrees = try container.decodeIfPresent(
            Double.self,
            forKey: .minimumRotationDegrees
        ) ?? Self.defaultMinimumRotationDegrees
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
        try container.encode(minimumScaleChange, forKey: .minimumScaleChange)
        try container.encode(minimumRotationDegrees, forKey: .minimumRotationDegrees)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (0.01...1.0).contains(minimumScaleChange) else {
            throw ConfigurationError.invalidValue("\(name).minimumScaleChange must be 0.01...1.0.")
        }
        guard (1...180).contains(minimumRotationDegrees) else {
            throw ConfigurationError.invalidValue("\(name).minimumRotationDegrees must be 1...180.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try region?.validate(name: "\(name).region")
        try actions.enumerated().forEach { try $0.element.validate(name: "\(name).actions[\($0.offset)]") }
    }
}
