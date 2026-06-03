import Foundation

public enum HoldPressKind: String, CaseIterable, Codable, Equatable, Sendable {
    case touch
    case click
    case forceClick

    public static let twoFingerLongPressCases: [HoldPressKind] = [.touch, .click]

    public var displayName: String {
        switch self {
        case .touch: return "Touch"
        case .click: return "Click"
        case .forceClick: return "Force Click"
        }
    }
}

public enum HoldTriggerTiming: String, CaseIterable, Codable, Equatable, Sendable {
    case whileTouching
    case afterRelease

    public var displayName: String {
        switch self {
        case .whileTouching: return "While Touching"
        case .afterRelease: return "After Release"
        }
    }
}
