import Foundation

public enum FourFingerTipTapSide: String, CaseIterable, Codable, Sendable {
    case auto
    case left
    case right

    public var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

public enum FourFingerTipTapSideReference: String, CaseIterable, Codable, Sendable {
    case relativeToFixedGroup
    case touchOrder
    case trackpad

    public var displayName: String {
        switch self {
        case .relativeToFixedGroup: return "Relative to Fixed Fingers"
        case .touchOrder: return "Finger Order"
        case .trackpad: return "Trackpad Area"
        }
    }
}

public struct FourFingerPressOptions: Codable, Equatable, Sendable {
    public var level: ThreeFingerPressLevel
    public var minimumPressure: Double
    public var forcePressure: Double
    public var triggerTiming: ThreeFingerPressTriggerTiming
    public var allowFallbackWithoutPressureData: Bool

    public init(
        level: ThreeFingerPressLevel = .normal,
        minimumPressure: Double = TrackpadPressureThreshold.click,
        forcePressure: Double = TrackpadPressureThreshold.forceClick,
        triggerTiming: ThreeFingerPressTriggerTiming = .pressDown,
        allowFallbackWithoutPressureData: Bool = false
    ) {
        self.level = level
        self.minimumPressure = minimumPressure
        self.forcePressure = forcePressure
        self.triggerTiming = triggerTiming
        self.allowFallbackWithoutPressureData = allowFallbackWithoutPressureData
    }

    public func validate(name: String) throws {
        guard (0.0...1.5).contains(minimumPressure),
              (0.0...1.5).contains(forcePressure) else {
            throw ConfigurationError.invalidValue("\(name).pressure thresholds must be 0.0...1.5.")
        }
    }
}

public struct FourFingerTipTapOptions: Codable, Equatable, Sendable {
    public var fixedFingers: Int
    public var tapSide: FourFingerTipTapSide
    public var sideReference: FourFingerTipTapSideReference
    public var tapCount: Int
    public var maximumTapMilliseconds: Int
    public var maximumActiveFingerMovement: Double
    public var maximumFixedFingerMovement: Double
    public var requireFixedFingersAlreadyDown: Bool
    public var minimumFixedFingerHoldMilliseconds: Int

    public init(
        fixedFingers: Int = 3,
        tapSide: FourFingerTipTapSide = .auto,
        sideReference: FourFingerTipTapSideReference = .relativeToFixedGroup,
        tapCount: Int = 1,
        maximumTapMilliseconds: Int = 180,
        maximumActiveFingerMovement: Double = 0.05,
        maximumFixedFingerMovement: Double = 0.03,
        requireFixedFingersAlreadyDown: Bool = true,
        minimumFixedFingerHoldMilliseconds: Int = 50
    ) {
        self.fixedFingers = fixedFingers
        self.tapSide = tapSide
        self.sideReference = sideReference
        self.tapCount = tapCount
        self.maximumTapMilliseconds = maximumTapMilliseconds
        self.maximumActiveFingerMovement = maximumActiveFingerMovement
        self.maximumFixedFingerMovement = maximumFixedFingerMovement
        self.requireFixedFingersAlreadyDown = requireFixedFingersAlreadyDown
        self.minimumFixedFingerHoldMilliseconds = minimumFixedFingerHoldMilliseconds
    }

    public func validate(name: String) throws {
        guard fixedFingers == 3 else {
            throw ConfigurationError.invalidValue("\(name).fixedFingers must be 3.")
        }
        guard [1, 2].contains(tapCount) else {
            throw ConfigurationError.invalidValue("\(name).tapCount must be 1 or 2.")
        }
        try ThreeFingerTouchOptions.validate(
            milliseconds: maximumTapMilliseconds,
            name: "\(name).maximumTapMilliseconds",
            lowerBound: 50
        )
        try ThreeFingerTouchOptions.validate(
            milliseconds: minimumFixedFingerHoldMilliseconds,
            name: "\(name).minimumFixedFingerHoldMilliseconds",
            lowerBound: 0
        )
        try validateMovement(maximumActiveFingerMovement, name: "\(name).maximumActiveFingerMovement")
        try validateMovement(maximumFixedFingerMovement, name: "\(name).maximumFixedFingerMovement")
    }
}

