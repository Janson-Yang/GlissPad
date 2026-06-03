import Foundation

public struct HoldGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var fingerCount: Int
    public var holdMilliseconds: Int
    public var maximumMovement: Double
    public var pressKind: HoldPressKind
    public var triggerTiming: HoldTriggerTiming
    public var minimumPressure: Double
    public var sustainingPressure: Double
    public var minimumForceMilliseconds: Int
    public var cooldownMilliseconds: Int
    public var region: NormalizedRegion?
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
        case holdMilliseconds
        case maximumMovement
        case pressKind
        case triggerTiming
        case minimumPressure
        case sustainingPressure
        case minimumForceMilliseconds
        case cooldownMilliseconds
        case region
        case action
        case actions
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int,
        holdMilliseconds: Int,
        maximumMovement: Double,
        pressKind: HoldPressKind = .touch,
        triggerTiming: HoldTriggerTiming = .whileTouching,
        minimumPressure: Double = TrackpadPressureThreshold.touch,
        sustainingPressure: Double? = nil,
        minimumForceMilliseconds: Int = 45,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.fingerCount = fingerCount
        self.holdMilliseconds = holdMilliseconds
        self.maximumMovement = maximumMovement
        self.pressKind = pressKind
        self.triggerTiming = triggerTiming
        self.minimumPressure = minimumPressure
        self.sustainingPressure = sustainingPressure ?? min(
            TrackpadPressureThreshold.sustain(for: pressKind),
            minimumPressure
        )
        self.minimumForceMilliseconds = minimumForceMilliseconds
        self.cooldownMilliseconds = cooldownMilliseconds
        self.region = region
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int,
        holdMilliseconds: Int,
        maximumMovement: Double,
        pressKind: HoldPressKind = .touch,
        triggerTiming: HoldTriggerTiming = .whileTouching,
        minimumPressure: Double = TrackpadPressureThreshold.touch,
        sustainingPressure: Double? = nil,
        minimumForceMilliseconds: Int = 45,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            fingerCount: fingerCount,
            holdMilliseconds: holdMilliseconds,
            maximumMovement: maximumMovement,
            pressKind: pressKind,
            triggerTiming: triggerTiming,
            minimumPressure: minimumPressure,
            sustainingPressure: sustainingPressure,
            minimumForceMilliseconds: minimumForceMilliseconds,
            cooldownMilliseconds: cooldownMilliseconds,
            region: region,
            actions: [.script(action)]
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        fingerCount = try container.decode(Int.self, forKey: .fingerCount)
        holdMilliseconds = try container.decode(Int.self, forKey: .holdMilliseconds)
        maximumMovement = try container.decode(Double.self, forKey: .maximumMovement)
        pressKind = try container.decodeIfPresent(HoldPressKind.self, forKey: .pressKind) ?? .touch
        triggerTiming = try container.decodeIfPresent(HoldTriggerTiming.self, forKey: .triggerTiming) ?? .whileTouching
        minimumPressure = try container.decodeIfPresent(Double.self, forKey: .minimumPressure)
            ?? TrackpadPressureThreshold.value(for: pressKind)
        sustainingPressure = try container.decodeIfPresent(Double.self, forKey: .sustainingPressure)
            ?? min(TrackpadPressureThreshold.sustain(for: pressKind), minimumPressure)
        minimumForceMilliseconds = try container.decodeIfPresent(Int.self, forKey: .minimumForceMilliseconds) ?? 45
        cooldownMilliseconds = try container.decode(Int.self, forKey: .cooldownMilliseconds)
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
        try container.encode(fingerCount, forKey: .fingerCount)
        try container.encode(holdMilliseconds, forKey: .holdMilliseconds)
        try container.encode(maximumMovement, forKey: .maximumMovement)
        try container.encode(pressKind, forKey: .pressKind)
        try container.encode(triggerTiming, forKey: .triggerTiming)
        try container.encode(minimumPressure, forKey: .minimumPressure)
        try container.encode(sustainingPressure, forKey: .sustainingPressure)
        try container.encode(minimumForceMilliseconds, forKey: .minimumForceMilliseconds)
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
        guard (100...30_000).contains(holdMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).holdMilliseconds must be 100...30000.")
        }
        guard (0.0...0.5).contains(maximumMovement) else {
            throw ConfigurationError.invalidValue("\(name).maximumMovement must be between 0.0 and 0.5.")
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
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try region?.validate(name: "\(name).region")
        for (index, action) in actions.enumerated() {
            try action.validate(name: "\(name).actions[\(index)]")
        }
    }
}
