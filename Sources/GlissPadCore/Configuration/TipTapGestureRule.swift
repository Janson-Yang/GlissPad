import Foundation

public enum TipTapActiveFinger: String, CaseIterable, Codable, Sendable {
    case auto
    case left
    case right

    public var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

public struct TipTapGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var activeFinger: TipTapActiveFinger
    public var maximumTapMilliseconds: Int
    public var stationaryMovement: Double
    public var tapMovement: Double
    public var cooldownMilliseconds: Int
    public var region: NormalizedRegion?
    public var actions: [GestureAction]

    enum CodingKeys: String, CodingKey {
        case name, isEnabled, activeFinger, maximumTapMilliseconds, stationaryMovement, tapMovement
        case cooldownMilliseconds, region, action, actions
    }

    public init(
        name: String,
        isEnabled: Bool,
        activeFinger: TipTapActiveFinger = .auto,
        maximumTapMilliseconds: Int = 300,
        stationaryMovement: Double = 0.04,
        tapMovement: Double = 0.06,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.activeFinger = activeFinger
        self.maximumTapMilliseconds = maximumTapMilliseconds
        self.stationaryMovement = stationaryMovement
        self.tapMovement = tapMovement
        self.cooldownMilliseconds = cooldownMilliseconds
        self.region = region
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        activeFinger = try container.decodeIfPresent(TipTapActiveFinger.self, forKey: .activeFinger) ?? .auto
        maximumTapMilliseconds = try container.decodeIfPresent(Int.self, forKey: .maximumTapMilliseconds) ?? 300
        stationaryMovement = try container.decodeIfPresent(Double.self, forKey: .stationaryMovement) ?? 0.04
        tapMovement = try container.decodeIfPresent(Double.self, forKey: .tapMovement) ?? 0.06
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
        try container.encode(activeFinger, forKey: .activeFinger)
        try container.encode(maximumTapMilliseconds, forKey: .maximumTapMilliseconds)
        try container.encode(stationaryMovement, forKey: .stationaryMovement)
        try container.encode(tapMovement, forKey: .tapMovement)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (50...1_000).contains(maximumTapMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).maximumTapMilliseconds must be 50...1000.")
        }
        guard (0.0...0.5).contains(stationaryMovement), (0.0...0.5).contains(tapMovement) else {
            throw ConfigurationError.invalidValue("\(name).movement tolerances must be between 0.0 and 0.5.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try region?.validate(name: "\(name).region")
        try actions.enumerated().forEach { try $0.element.validate(name: "\(name).actions[\($0.offset)]") }
    }
}
