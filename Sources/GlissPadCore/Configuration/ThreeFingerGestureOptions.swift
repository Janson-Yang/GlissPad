import Foundation

public enum ThreeFingerTouchEvent: String, CaseIterable, Codable, Sendable {
    case touchStart
    case longTouch
    case touchEnd

    public var displayName: String {
        switch self {
        case .touchStart: return "Touch Start"
        case .longTouch: return "Long Touch"
        case .touchEnd: return "Touch End"
        }
    }
}

public enum ThreeFingerTriggerTiming: String, CaseIterable, Codable, Sendable {
    case thresholdReached
    case release
    case continuous

    public var displayName: String {
        switch self {
        case .thresholdReached: return "Threshold Reached"
        case .release: return "Release"
        case .continuous: return "Continuous"
        }
    }
}

public enum ThreeFingerDirection: String, CaseIterable, Codable, Sendable {
    case up
    case down
    case left
    case right

    public var displayName: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

public enum ThreeFingerPressLevel: String, CaseIterable, Codable, Sendable {
    case normal
    case force

    public var displayName: String {
        switch self {
        case .normal: return "Normal Click"
        case .force: return "Force Click"
        }
    }
}

public enum ThreeFingerPressureBias: String, CaseIterable, Codable, Sendable {
    case none
    case left
    case middle
    case right

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .left: return "Left Finger Harder"
        case .middle: return "Middle Finger Harder"
        case .right: return "Right Finger Harder"
        }
    }
}

public enum ThreeFingerPressTriggerTiming: String, CaseIterable, Codable, Sendable {
    case pressDown
    case pressUp

    public var displayName: String {
        switch self {
        case .pressDown: return "Press Down"
        case .pressUp: return "Release"
        }
    }
}

public enum ThreeFingerSwipePressMode: String, CaseIterable, Codable, Sendable {
    case none
    case clickHeld
    case forceClickHeld

    public var displayName: String {
        switch self {
        case .none: return "Normal Swipe"
        case .clickHeld: return "Click Held Swipe"
        case .forceClickHeld: return "Force Click Held Swipe"
        }
    }
}

public enum ThreeFingerPosition: String, CaseIterable, Codable, Sendable {
    case left
    case middle
    case right

    public var displayName: String {
        switch self {
        case .left: return "Left"
        case .middle: return "Middle"
        case .right: return "Right"
        }
    }
}

public enum ThreeFingerActiveFinger: String, CaseIterable, Codable, Sendable {
    case auto
    case left
    case middle
    case right

    public var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .left: return "Left"
        case .middle: return "Middle"
        case .right: return "Right"
        }
    }
}

public enum ThreeFingerFingerReference: String, CaseIterable, Codable, Sendable {
    case touchOrder
    case trackpad

    public var displayName: String {
        switch self {
        case .touchOrder: return "Touch Order"
        case .trackpad: return "Trackpad Position"
        }
    }
}

public enum ThreeFingerScaleDirection: String, CaseIterable, Codable, Sendable {
    case pinchIn
    case spreadOut
    case any

    public var displayName: String {
        switch self {
        case .pinchIn: return "Pinch In"
        case .spreadOut: return "Spread Out"
        case .any: return "Either"
        }
    }
}

public enum ThreeFingerThumbDetectionMode: String, CaseIterable, Codable, Sendable {
    case system
    case heuristic
    case disabledFallback

    public var displayName: String {
        switch self {
        case .system: return "System"
        case .heuristic: return "Heuristic"
        case .disabledFallback: return "Disabled Fallback"
        }
    }
}

public enum ThreeFingerDrawingPathSource: String, CaseIterable, Codable, Sendable {
    case centroid
    case allFingersAverage

    public var displayName: String {
        switch self {
        case .centroid: return "Centroid"
        case .allFingersAverage: return "All Fingers Average"
        }
    }
}

public enum ThreeFingerDrawingRecognitionMode: String, CaseIterable, Codable, Sendable {
    case templateMatch
    case directionSequence

    public var displayName: String {
        switch self {
        case .templateMatch: return "Template Match"
        case .directionSequence: return "Direction Sequence"
        }
    }
}

