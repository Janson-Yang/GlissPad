import GlissPadCore

extension GestureTriggerType {
    var symbolName: String {
        switch self {
        case .oneFingerTouchStart: return "trigger-one-finger-touch-start"
        case .oneFingerLongPress: return "trigger-one-finger-long-press"
        case .oneFingerCircle: return "trigger-one-finger-circle"
        case .oneFingerSquare: return "trigger-one-finger-square"
        case .oneFingerTriangle: return "trigger-one-finger-triangle"
        case .oneFingerCornerClick: return "trigger-one-finger-corner-click"
        case .oneFingerTap: return "trigger-one-finger-tap"
        case .oneFingerDoubleTap: return "trigger-one-finger-double-tap"
        case .oneFingerPress: return "trigger-one-finger-press"
        case .oneFingerCustomPath: return "trigger-one-finger-custom-path"
        case .oneFingerDrawnPath: return "trigger-one-finger-drawn-path"
        case .twoFingerTouchStart: return "trigger-two-finger-touch-start"
        case .twoFingerTap: return "trigger-two-finger-tap"
        case .tipTap: return "trigger-two-finger-tip-tap"
        case .pinchIn: return "trigger-two-finger-pinch-in"
        case .pinchOut: return "trigger-two-finger-pinch-out"
        case .rotateLeft: return "rotate.left.fill"
        case .rotateRight: return "rotate.right.fill"
        case .freeformTwoFingerSwipe: return "trigger-two-finger-free-swipe"
        case .regionTwoFingerSwipe: return "trigger-two-finger-region-swipe"
        case .threeFingerForcePress: return "trigger-three-finger-force-press"
        case .upperLeftForcePress: return "trigger-top-left-force-press"
        case .leftEdgeTwoFingerSwipe: return "trigger-left-edge-two-finger-swipe"
        case .twoFingerHold: return "trigger-two-finger-hold"
        case .upperRightForcePress: return "trigger-top-right-click"
        case .releaseLastFinger: return "trigger-release-last-finger"
        case .threeFingerTouch: return "trigger-three-finger-touch"
        case .threeFingerTap: return "trigger-three-finger-tap"
        case .threeFingerPress: return "trigger-three-finger-press"
        case .threeFingerSwipe: return "trigger-three-finger-swipe"
        case .threeFingerTipTap: return "trigger-three-finger-tip-tap"
        case .threeFingerTipSwipe: return "trigger-three-finger-tip-swipe"
        case .thumbTwoFingerScale: return "trigger-thumb-two-finger-scale"
        case .threeFingerDrawing: return "trigger-three-finger-drawing"
        }
    }
}
