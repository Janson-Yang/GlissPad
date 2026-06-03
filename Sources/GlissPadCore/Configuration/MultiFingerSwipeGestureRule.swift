import Foundation

public enum MultiFingerSwipePathPreset: String, CaseIterable, Codable, Sendable {
    case right
    case left
    case up
    case down
    case upLeft
    case upRight
    case downLeft
    case downRight
    case custom

    public var displayName: String {
        switch self {
        case .right: return "Right"
        case .left: return "Left"
        case .up: return "Up"
        case .down: return "Down"
        case .upLeft: return "Up Left"
        case .upRight: return "Up Right"
        case .downLeft: return "Down Left"
        case .downRight: return "Down Right"
        case .custom: return "Custom"
        }
    }

    public var defaultPoints: [NormalizedPoint] {
        switch self {
        case .right: return [.init(x: 0.2, y: 0.5), .init(x: 0.8, y: 0.5)]
        case .left: return [.init(x: 0.8, y: 0.5), .init(x: 0.2, y: 0.5)]
        case .up: return [.init(x: 0.5, y: 0.2), .init(x: 0.5, y: 0.8)]
        case .down: return [.init(x: 0.5, y: 0.8), .init(x: 0.5, y: 0.2)]
        case .upLeft: return [.init(x: 0.8, y: 0.2), .init(x: 0.2, y: 0.8)]
        case .upRight: return [.init(x: 0.2, y: 0.2), .init(x: 0.8, y: 0.8)]
        case .downLeft: return [.init(x: 0.8, y: 0.8), .init(x: 0.2, y: 0.2)]
        case .downRight: return [.init(x: 0.2, y: 0.8), .init(x: 0.8, y: 0.2)]
        case .custom: return Self.right.defaultPoints
        }
    }
}

public struct MultiFingerSwipeGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var fingerCount: Int
    public var pathPreset: MultiFingerSwipePathPreset
    public var points: [NormalizedPoint]
    public var pointTolerance: Double
    public var minimumTravel: Double
    public var startRegion: NormalizedRegion?
    public var endRegion: NormalizedRegion?
    public var cooldownMilliseconds: Int
    public var actions: [GestureAction]

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int = 2,
        pathPreset: MultiFingerSwipePathPreset = .right,
        points: [NormalizedPoint]? = nil,
        pointTolerance: Double = 0.16,
        minimumTravel: Double = 0.18,
        startRegion: NormalizedRegion? = nil,
        endRegion: NormalizedRegion? = nil,
        cooldownMilliseconds: Int,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.fingerCount = fingerCount
        self.pathPreset = pathPreset
        self.points = points ?? pathPreset.defaultPoints
        self.pointTolerance = pointTolerance
        self.minimumTravel = minimumTravel
        self.startRegion = startRegion
        self.endRegion = endRegion
        self.cooldownMilliseconds = cooldownMilliseconds
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String,
        isEnabled: Bool,
        fingerCount: Int = 2,
        pathPreset: MultiFingerSwipePathPreset = .right,
        startRegion: NormalizedRegion? = nil,
        endRegion: NormalizedRegion? = nil,
        cooldownMilliseconds: Int,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            fingerCount: fingerCount,
            pathPreset: pathPreset,
            startRegion: startRegion,
            endRegion: endRegion,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: [.script(action)]
        )
    }

    public func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (2...5).contains(fingerCount) else {
            throw ConfigurationError.invalidValue("\(name).fingerCount must be between 2 and 5.")
        }
        guard (2...64).contains(points.count) else {
            throw ConfigurationError.invalidValue("\(name).points must contain 2...64 points.")
        }
        guard (0.02...0.35).contains(pointTolerance) else {
            throw ConfigurationError.invalidValue("\(name).pointTolerance must be between 0.02 and 0.35.")
        }
        guard (0.03...1.2).contains(minimumTravel) else {
            throw ConfigurationError.invalidValue("\(name).minimumTravel must be between 0.03 and 1.2.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try startRegion?.validate(name: "\(name).startRegion")
        try endRegion?.validate(name: "\(name).endRegion")
        for (index, action) in actions.enumerated() {
            try action.validate(name: "\(name).actions[\(index)]")
        }
    }
}
