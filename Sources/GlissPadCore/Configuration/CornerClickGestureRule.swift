import Foundation

public struct CornerClickGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var corner: TrackpadCorner
    public var clickKind: CornerClickKind
    public var minimumPressure: Double
    public var sustainingPressure: Double
    public var minimumForceMilliseconds: Int
    public var maximumMovement: Double
    public var cooldownMilliseconds: Int
    public var region: NormalizedRegion
    public var actions: [GestureAction]

    public var action: ScriptAction {
        get { actions.first?.scriptAction ?? ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript) }
        set { actions = GestureActionsCoding.scriptActions([newValue]) }
    }

    enum CodingKeys: String, CodingKey {
        case name, isEnabled, corner, clickKind, minimumPressure, sustainingPressure, minimumForceMilliseconds
        case maximumMovement, cooldownMilliseconds, region, action, actions
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        corner: TrackpadCorner,
        clickKind: CornerClickKind,
        minimumPressure: Double = TrackpadPressureThreshold.click,
        sustainingPressure: Double? = nil,
        minimumForceMilliseconds: Int = 45,
        maximumMovement: Double = 0.045,
        cooldownMilliseconds: Int,
        region: NormalizedRegion,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.corner = corner
        self.clickKind = clickKind
        self.minimumPressure = minimumPressure
        self.sustainingPressure = sustainingPressure ?? min(
            TrackpadPressureThreshold.sustain(for: clickKind),
            minimumPressure
        )
        self.minimumForceMilliseconds = minimumForceMilliseconds
        self.maximumMovement = maximumMovement
        self.cooldownMilliseconds = cooldownMilliseconds
        self.region = region
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        corner: TrackpadCorner,
        clickKind: CornerClickKind,
        cooldownMilliseconds: Int,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            corner: corner,
            clickKind: clickKind,
            minimumPressure: TrackpadPressureThreshold.value(for: clickKind),
            cooldownMilliseconds: cooldownMilliseconds,
            region: corner.defaultRegion,
            actions: GestureActionsCoding.scriptActions([action])
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        corner = try container.decodeIfPresent(TrackpadCorner.self, forKey: .corner) ?? .upperRight
        clickKind = try container.decodeIfPresent(CornerClickKind.self, forKey: .clickKind) ?? .click
        minimumPressure = try container.decodeIfPresent(Double.self, forKey: .minimumPressure)
            ?? TrackpadPressureThreshold.value(for: clickKind)
        sustainingPressure = try container.decodeIfPresent(Double.self, forKey: .sustainingPressure)
            ?? min(TrackpadPressureThreshold.sustain(for: clickKind), minimumPressure)
        minimumForceMilliseconds = try container.decodeIfPresent(Int.self, forKey: .minimumForceMilliseconds) ?? 45
        maximumMovement = try container.decodeIfPresent(Double.self, forKey: .maximumMovement) ?? 0.045
        cooldownMilliseconds = try container.decodeIfPresent(Int.self, forKey: .cooldownMilliseconds) ?? 650
        region = try container.decodeIfPresent(NormalizedRegion.self, forKey: .region) ?? corner.defaultRegion
        actions = try GestureActionsCoding.decode(from: container, actionKey: .action, actionsKey: .actions) { _ in
            ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(corner, forKey: .corner)
        try container.encode(clickKind, forKey: .clickKind)
        try container.encode(minimumPressure, forKey: .minimumPressure)
        try container.encode(sustainingPressure, forKey: .sustainingPressure)
        try container.encode(minimumForceMilliseconds, forKey: .minimumForceMilliseconds)
        try container.encode(maximumMovement, forKey: .maximumMovement)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encode(region, forKey: .region)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (0.0...1.5).contains(minimumPressure) else {
            throw ConfigurationError.invalidValue("\(name).minimumPressure must be between 0.0 and 1.5.")
        }
        guard (0.0...1.5).contains(sustainingPressure), sustainingPressure <= minimumPressure else {
            throw ConfigurationError.invalidValue("\(name).sustainingPressure must be 0.0...minimumPressure.")
        }
        guard (0...1_000).contains(minimumForceMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).minimumForceMilliseconds must be 0...1000.")
        }
        guard (0.0...0.5).contains(maximumMovement) else {
            throw ConfigurationError.invalidValue("\(name).maximumMovement must be between 0.0 and 0.5.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try region.validate(name: "\(name).region")
        try actions.enumerated().forEach { try $0.element.validate(name: "\(name).actions[\($0.offset)]") }
    }
}
