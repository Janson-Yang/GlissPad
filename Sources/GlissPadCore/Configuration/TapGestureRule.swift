import Foundation

public struct TapGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var fingerCount: Int
    public var tapCount: Int
    public var maximumTapMilliseconds: Int
    public var doubleTapMaximumIntervalMilliseconds: Int
    public var maximumMovement: Double
    public var pressKind: HoldPressKind
    public var minimumPressure: Double
    public var sustainingPressure: Double
    public var minimumForceMilliseconds: Int
    public var cooldownMilliseconds: Int
    public var region: NormalizedRegion?
    public var actions: [GestureAction]

    public var action: ScriptAction {
        get { actions.first?.scriptAction ?? ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript) }
        set { actions = GestureActionsCoding.scriptActions([newValue]) }
    }

    enum CodingKeys: String, CodingKey {
        case name, isEnabled, fingerCount, tapCount, maximumTapMilliseconds, doubleTapMaximumIntervalMilliseconds
        case maximumMovement, pressKind, minimumPressure, sustainingPressure, minimumForceMilliseconds
        case cooldownMilliseconds, region, action, actions
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        fingerCount: Int = 1,
        tapCount: Int,
        maximumTapMilliseconds: Int = 250,
        doubleTapMaximumIntervalMilliseconds: Int = 350,
        maximumMovement: Double = 0.045,
        pressKind: HoldPressKind = .touch,
        minimumPressure: Double? = nil,
        sustainingPressure: Double? = nil,
        minimumForceMilliseconds: Int = 45,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.fingerCount = fingerCount
        self.tapCount = tapCount
        self.maximumTapMilliseconds = maximumTapMilliseconds
        self.doubleTapMaximumIntervalMilliseconds = doubleTapMaximumIntervalMilliseconds
        self.maximumMovement = maximumMovement
        self.pressKind = pressKind
        self.minimumPressure = minimumPressure ?? TrackpadPressureThreshold.value(for: pressKind)
        self.sustainingPressure = sustainingPressure ?? min(
            TrackpadPressureThreshold.sustain(for: pressKind),
            self.minimumPressure
        )
        self.minimumForceMilliseconds = minimumForceMilliseconds
        self.cooldownMilliseconds = cooldownMilliseconds
        self.region = region
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        fingerCount: Int = 1,
        tapCount: Int,
        cooldownMilliseconds: Int,
        region: NormalizedRegion? = nil,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            fingerCount: fingerCount,
            tapCount: tapCount,
            cooldownMilliseconds: cooldownMilliseconds,
            region: region,
            actions: GestureActionsCoding.scriptActions([action])
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        fingerCount = try container.decodeIfPresent(Int.self, forKey: .fingerCount) ?? 1
        tapCount = try container.decodeIfPresent(Int.self, forKey: .tapCount) ?? 1
        maximumTapMilliseconds = try container.decodeIfPresent(Int.self, forKey: .maximumTapMilliseconds) ?? 250
        doubleTapMaximumIntervalMilliseconds = try container.decodeIfPresent(
            Int.self,
            forKey: .doubleTapMaximumIntervalMilliseconds
        ) ?? 350
        maximumMovement = try container.decodeIfPresent(Double.self, forKey: .maximumMovement) ?? 0.045
        pressKind = try container.decodeIfPresent(HoldPressKind.self, forKey: .pressKind) ?? .touch
        minimumPressure = try container.decodeIfPresent(Double.self, forKey: .minimumPressure)
            ?? TrackpadPressureThreshold.value(for: pressKind)
        sustainingPressure = try container.decodeIfPresent(Double.self, forKey: .sustainingPressure)
            ?? min(TrackpadPressureThreshold.sustain(for: pressKind), minimumPressure)
        minimumForceMilliseconds = try container.decodeIfPresent(Int.self, forKey: .minimumForceMilliseconds) ?? 45
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
        try container.encode(tapCount, forKey: .tapCount)
        try container.encode(maximumTapMilliseconds, forKey: .maximumTapMilliseconds)
        try container.encode(doubleTapMaximumIntervalMilliseconds, forKey: .doubleTapMaximumIntervalMilliseconds)
        try container.encode(maximumMovement, forKey: .maximumMovement)
        try container.encode(pressKind, forKey: .pressKind)
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
        guard [1, 2].contains(tapCount) else {
            throw ConfigurationError.invalidValue("\(name).tapCount must be 1 or 2.")
        }
        guard (50...1_000).contains(maximumTapMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).maximumTapMilliseconds must be 50...1000.")
        }
        guard (100...2_000).contains(doubleTapMaximumIntervalMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).doubleTapMaximumIntervalMilliseconds must be 100...2000.")
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
        try actions.enumerated().forEach { try $0.element.validate(name: "\(name).actions[\($0.offset)]") }
    }
}
