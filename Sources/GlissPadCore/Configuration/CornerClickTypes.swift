import Foundation

public enum TrackpadCorner: String, CaseIterable, Codable, Equatable, Sendable {
    case upperLeft
    case upperRight
    case lowerLeft
    case lowerRight
    case custom

    public var displayName: String {
        switch self {
        case .upperLeft: return "Top Left"
        case .upperRight: return "Top Right"
        case .lowerLeft: return "Bottom Left"
        case .lowerRight: return "Bottom Right"
        case .custom: return "Custom"
        }
    }

    public var defaultRegion: NormalizedRegion {
        switch self {
        case .upperLeft:
            return NormalizedRegion(minX: 0.0, maxX: 0.22, minY: 0.72, maxY: 1.0)
        case .upperRight:
            return NormalizedRegion(minX: 0.78, maxX: 1.0, minY: 0.72, maxY: 1.0)
        case .lowerLeft:
            return NormalizedRegion(minX: 0.0, maxX: 0.22, minY: 0.0, maxY: 0.28)
        case .lowerRight:
            return NormalizedRegion(minX: 0.78, maxX: 1.0, minY: 0.0, maxY: 0.28)
        case .custom:
            return NormalizedRegion(minX: 0.78, maxX: 1.0, minY: 0.72, maxY: 1.0)
        }
    }
}

public enum CornerClickKind: String, CaseIterable, Codable, Equatable, Sendable {
    case tap
    case click
    case forceClick

    public var displayName: String {
        switch self {
        case .tap: return "Tap"
        case .click: return "Click"
        case .forceClick: return "Force Click"
        }
    }
}
