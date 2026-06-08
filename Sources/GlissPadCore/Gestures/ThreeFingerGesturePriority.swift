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

    var fourFingerPriority: Int {
        switch self {
        case .fourFingerPress: return 90
        case .thumbThreeFingerScale: return 80
        case .fourFingerDrawing: return 70
        case .fourFingerSwipe: return 50
        case .fourFingerTipTap: return 40
        case .fourFingerTouch:
            return 10
        case .fourFingerTap:
            return 20
        default:
            return 0
        }
    }

    var multiFingerPriority: Int {
        if isFiveAndMoreFingerGestureFamily { return fiveAndMoreFingerPriority }
        return isFourFingerGestureFamily ? fourFingerPriority : threeFingerPriority
    }

    var isMultiFingerGestureFamily: Bool {
        isThreeFingerGestureFamily || isFourFingerGestureFamily || isFiveAndMoreFingerGestureFamily
    }

    private var fiveAndMoreFingerPriority: Int {
        switch self {
        case .wholeHandTap: return 100
        case .fiveFingerPress: return 90
        case .thumbFourFingerScale: return 80
        case .fiveFingerDrawing: return 70
        case .fiveFingerSwipe: return 50
        case .fiveFingerTouch: return 10
        case .fiveFingerTap: return 20
        default: return 0
        }
    }
}
