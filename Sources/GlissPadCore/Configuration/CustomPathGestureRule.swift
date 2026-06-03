import Foundation

public struct CustomPathGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var points: [NormalizedPoint]
    public var pointTolerance: Double
    public var cooldownMilliseconds: Int
    public var actions: [GestureAction]

    public var action: ScriptAction {
        get { actions.first?.scriptAction ?? ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript) }
        set { actions = GestureActionsCoding.scriptActions([newValue]) }
    }

    enum CodingKeys: String, CodingKey {
        case name, isEnabled, points, pointTolerance, cooldownMilliseconds, action, actions
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        points: [NormalizedPoint],
        pointTolerance: Double = 0.08,
        cooldownMilliseconds: Int,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.points = points
        self.pointTolerance = pointTolerance
        self.cooldownMilliseconds = cooldownMilliseconds
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String = "",
        isEnabled: Bool,
        points: [NormalizedPoint],
        cooldownMilliseconds: Int,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            points: points,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: GestureActionsCoding.scriptActions([action])
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        points = try container.decodeIfPresent([NormalizedPoint].self, forKey: .points) ?? Self.defaultPoints
        pointTolerance = try container.decodeIfPresent(Double.self, forKey: .pointTolerance) ?? 0.08
        cooldownMilliseconds = try container.decodeIfPresent(Int.self, forKey: .cooldownMilliseconds) ?? 650
        actions = try GestureActionsCoding.decode(from: container, actionKey: .action, actionsKey: .actions) { _ in
            ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(points, forKey: .points)
        try container.encode(pointTolerance, forKey: .pointTolerance)
        try container.encode(cooldownMilliseconds, forKey: .cooldownMilliseconds)
        try container.encode(actions, forKey: .actions)
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (2...120).contains(points.count) else {
            throw ConfigurationError.invalidValue("\(name).points must contain 2...120 points.")
        }
        try points.enumerated().forEach { try validate($0.element, name: "\(name).points[\($0.offset)]") }
        guard (0.02...0.3).contains(pointTolerance) else {
            throw ConfigurationError.invalidValue("\(name).pointTolerance must be between 0.02 and 0.3.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try actions.enumerated().forEach { try $0.element.validate(name: "\(name).actions[\($0.offset)]") }
    }

    public static let defaultPoints = [
        NormalizedPoint(x: 0.2, y: 0.75),
        NormalizedPoint(x: 0.5, y: 0.25),
        NormalizedPoint(x: 0.8, y: 0.75)
    ]

    public static let defaultDrawnPathPoints = [
        NormalizedPoint(x: 0.20, y: 0.55),
        NormalizedPoint(x: 0.35, y: 0.72),
        NormalizedPoint(x: 0.55, y: 0.70),
        NormalizedPoint(x: 0.72, y: 0.52),
        NormalizedPoint(x: 0.56, y: 0.34),
        NormalizedPoint(x: 0.34, y: 0.36)
    ]

    private func validate(_ point: NormalizedPoint, name: String) throws {
        guard (0.0...1.0).contains(point.x), (0.0...1.0).contains(point.y) else {
            throw ConfigurationError.invalidValue("\(name) must be normalized 0.0...1.0.")
        }
    }
}
