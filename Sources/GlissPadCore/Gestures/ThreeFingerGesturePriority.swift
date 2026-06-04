import Foundation

extension GestureTriggerType {
    var threeFingerPriority: Int {
        switch self {
        case .threeFingerPress: return 90
        case .thumbTwoFingerScale: return 80
        case .threeFingerDrawing: return 70
        case .threeFingerTipSwipe: return 60
        case .threeFingerSwipe: return 50
        case .threeFingerTipTap: return 40
        case .threeFingerTouch: return 10
        default: return 0
        }
    }
}

