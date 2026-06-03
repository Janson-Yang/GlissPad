import Foundation

public enum GestureTriggerType: String, CaseIterable, Codable, Equatable, Sendable {
    case oneFingerTouchStart
    case oneFingerLongPress
    case oneFingerCircle
    case oneFingerSquare
    case oneFingerTriangle
    case oneFingerCornerClick
    case oneFingerTap
    case oneFingerDoubleTap
    case oneFingerPress
    case oneFingerCustomPath
    case oneFingerDrawnPath
    case twoFingerTouchStart
    case twoFingerTap
    case tipTap
    case pinchIn
    case pinchOut
    case rotateLeft
    case rotateRight
    case freeformTwoFingerSwipe
    case regionTwoFingerSwipe
    case threeFingerForcePress
    case upperLeftForcePress
    case leftEdgeTwoFingerSwipe
    case twoFingerHold
    case upperRightForcePress
    case releaseLastFinger

    public var displayName: String {
        switch self {
        case .oneFingerTouchStart: return "Touch Start"
        case .oneFingerLongPress: return "Long Press"
        case .oneFingerCircle: return "Circle"
        case .oneFingerSquare: return "Square"
        case .oneFingerTriangle: return "Triangle"
        case .oneFingerCornerClick: return "Corner Click"
        case .oneFingerTap: return "Tap"
        case .oneFingerDoubleTap: return "Double Tap"
        case .oneFingerPress: return "Press"
        case .oneFingerCustomPath: return "Custom Path"
        case .oneFingerDrawnPath: return "Drawn Custom Path"
        case .twoFingerTouchStart: return "2 Finger Touch Start"
        case .twoFingerTap: return "2 Finger Tap"
        case .tipTap: return "Tip Tap"
        case .pinchIn: return "Pinch In"
        case .pinchOut: return "Pinch Out"
        case .rotateLeft: return "Rotate Left"
        case .rotateRight: return "Rotate Right"
        case .freeformTwoFingerSwipe: return "2 Finger Free Swipe"
        case .regionTwoFingerSwipe: return "2 Finger Region Swipe"
        case .threeFingerForcePress: return "3 Finger Force Touch"
        case .upperLeftForcePress: return "Top Left Force Touch"
        case .leftEdgeTwoFingerSwipe: return "2 Finger Left Edge Swipe"
        case .twoFingerHold: return "2 Finger Long Press"
        case .upperRightForcePress: return "Top Right Click"
        case .releaseLastFinger: return "Release Last Finger"
        }
    }

    var defaultID: String {
        rawValue
    }
}
