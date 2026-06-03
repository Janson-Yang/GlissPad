import Foundation

public struct PressGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var fingerCount: Int
    public var minimumPressure: Double
    public var sustainingPressure: Double
    public var minimumForceMilliseconds: Int
    public var maximumMovement: Double
    public var cooldownMilliseconds: Int
    public var region: NormalizedRegion?
    public var requiresClick: Bool
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
        case minimumPressure
        case sustainingPressure
        case minimumForceMilliseconds
        case maximumMovement
        case cooldownMilliseconds
        case region
        case requiresClick
        case action
        case actions
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int,
        minimumPressure: Double,
        sustainingPressure: Double = TrackpadPressureThreshold.forceClickSustain,
        minimumForceMilliseconds: Int = 45,
        maximumMovement: Double = 0.045,
        cooldownMilliseconds: Int,
        region: NormalizedRegion?,
        requiresClick: Bool = false,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.fingerCount = fingerCount
        self.minimumPressure = minimumPressure
        self.sustainingPressure = sustainingPressure
        self.minimumForceMilliseconds = minimumForceMilliseconds
        self.maximumMovement = maximumMovement
        self.cooldownMilliseconds = cooldownMilliseconds
        self.region = region
        self.requiresClick = requiresClick
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int,
        minimumPressure: Double,
        sustainingPressure: Double = TrackpadPressureThreshold.forceClickSustain,
        minimumForceMilliseconds: Int = 45,
        maximumMovement: Double = 0.045,
        cooldownMilliseconds: Int,
        region: NormalizedRegion?,
        requiresClick: Bool = false,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            fingerCount: fingerCount,
            minimumPressure: minimumPressure,
            sustainingPressure: sustainingPressure,
            minimumForceMilliseconds: minimumForceMilliseconds,
            maximumMovement: maximumMovement,
            cooldownMilliseconds: cooldownMilliseconds,
            region: region,
            requiresClick: requiresClick,
            actions: [.script(action)]
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        fingerCount = try container.decode(Int.self, forKey: .fingerCount)
        minimumPressure = try container.decode(Double.self, forKey: .minimumPressure)
        sustainingPressure = try container.decodeIfPresent(Double.self, forKey: .sustainingPressure)
            ?? min(TrackpadPressureThreshold.forceClickSustain, minimumPressure)
        minimumForceMilliseconds = try container.decodeIfPresent(
            Int.self,
            forKey: .minimumForceMilliseconds
        ) ?? 45
        maximumMovement = try container.decodeIfPresent(Double.self, forKey: .maximumMovement) ?? 0.045
        cooldownMilliseconds = try container.decode(Int.self, forKey: .cooldownMilliseconds)
        region = try container.decodeIfPresent(NormalizedRegion.self, forKey: .region)
        requiresClick = try container.decodeIfPresent(Bool.self, forKey: .requiresClick) ?? false
        actions = try Self.decodeActions(from: container)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(fingerCount, forKey: .fingerCount)
        try container.encode(minimumPressure, forKey: .minimumPressure)
        try container.encode(sustainingPressure, forKey: .sustainingPressure)
        try container.encode(minimumForceMilliseconds, forKey: .minimumForceMilliseconds)
        try container.encode(maximumMovement, forKey: .maximumMovement)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encode(requiresClick, forKey: .requiresClick)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (1...5).contains(fingerCount) else {
            throw ConfigurationError.invalidValue("\(name).fingerCount must be between 1 and 5.")
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
        try region?.validate(name: "\(name).region")
        for (index, action) in actions.enumerated() {
            try action.validate(name: "\(name).actions[\(index)]")
        }
    }

    private static func decodeActions(from container: KeyedDecodingContainer<CodingKeys>) throws -> [GestureAction] {
        try GestureActionsCoding.decode(from: container, actionKey: .action, actionsKey: .actions) { legacyAction in
            legacyAction == "toggleKeyboardViewer"
                ? ScriptAction(language: .appleScript, script: DefaultScripts.toggleKeyboardViewer)
                : ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
    }
}

public struct NormalizedRegion: Codable, Equatable, Sendable {
    public var minX: Double
    public var maxX: Double
    public var minY: Double
    public var maxY: Double

    public init(minX: Double, maxX: Double, minY: Double, maxY: Double) {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    public func contains(_ point: NormalizedPoint) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }

    public func validate(name: String) throws {
        let values = [minX, maxX, minY, maxY]
        guard values.allSatisfy({ (0.0...1.0).contains($0) }) else {
            throw ConfigurationError.invalidValue("\(name) values must be normalized 0.0...1.0.")
        }
        guard minX <= maxX, minY <= maxY else {
            throw ConfigurationError.invalidValue("\(name) minimums must be <= maximums.")
        }
    }
}

enum ConfigurationError: Error, CustomStringConvertible, Sendable {
    case invalidValue(String)

    var description: String {
        switch self {
        case .invalidValue(let message):
            return message
        }
    }
}
