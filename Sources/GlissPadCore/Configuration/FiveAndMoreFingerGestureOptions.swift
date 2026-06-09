import Foundation

public enum FiveFingerTouchEvent: String, CaseIterable, Codable, Sendable {
    case touchStart
    case stableTouch
    case longTouch
    case touchEnd

    public var displayName: String {
        switch self {
        case .touchStart: return "Touch Start"
        case .stableTouch: return "Stable Touch"
        case .longTouch: return "Long Touch"
        case .touchEnd: return "Touch End"
        }
    }
}

public enum WholeHandPalmDetectionMode: String, CaseIterable, Codable, Sendable {
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

public struct FiveFingerTouchOptions: Codable, Equatable, Sendable {
    public var event: FiveFingerTouchEvent
    public var holdMilliseconds: Int
    public var stableMilliseconds: Int
    public var movementTolerance: Double
    public var cancelOnMovement: Bool
    public var cancelOnPress: Bool
    public var repeatWhileHolding: Bool
    public var repeatIntervalMilliseconds: Int
    public var triggerTiming: ThreeFingerTriggerTiming

    public init(
        event: FiveFingerTouchEvent = .touchStart,
        holdMilliseconds: Int = 550,
        stableMilliseconds: Int = 60,
        movementTolerance: Double = 0.09,
        cancelOnMovement: Bool = true,
        cancelOnPress: Bool = true,
        repeatWhileHolding: Bool = false,
        repeatIntervalMilliseconds: Int = 300,
        triggerTiming: ThreeFingerTriggerTiming = .thresholdReached
    ) {
        self.event = event
        self.holdMilliseconds = holdMilliseconds
        self.stableMilliseconds = stableMilliseconds
        self.movementTolerance = movementTolerance
        self.cancelOnMovement = cancelOnMovement
        self.cancelOnPress = cancelOnPress
        self.repeatWhileHolding = repeatWhileHolding
        self.repeatIntervalMilliseconds = repeatIntervalMilliseconds
        self.triggerTiming = triggerTiming
    }

    public func validate(name: String) throws {
        try ThreeFingerTouchOptions.validate(
            milliseconds: holdMilliseconds,
            name: "\(name).holdMilliseconds",
            lowerBound: 100
        )
        try ThreeFingerTouchOptions.validate(
            milliseconds: stableMilliseconds,
            name: "\(name).stableMilliseconds",
            lowerBound: 0
        )
        try ThreeFingerTouchOptions.validate(
            milliseconds: repeatIntervalMilliseconds,
            name: "\(name).repeatIntervalMilliseconds",
            lowerBound: 50
        )
        guard (0.0...0.5).contains(movementTolerance) else {
            throw ConfigurationError.invalidValue("\(name).movementTolerance must be 0.0...0.5.")
        }
    }
}

public struct WholeHandTapOptions: Codable, Equatable, Sendable {
    public var nominalContactCount: Int
    public var minContactCount: Int
    public var maxContactCount: Int?
    public var requireLargeContactArea: Bool
    public var minTotalContactArea: Double
    public var minAverageContactArea: Double
    public var requirePalmLikeContact: Bool
    public var palmDetectionMode: WholeHandPalmDetectionMode
    public var minTapMilliseconds: Int
    public var maxTapMilliseconds: Int
    public var maximumMovement: Double
    public var region: NormalizedRegion?

    public init(
        nominalContactCount: Int = 11,
        minContactCount: Int = 8,
        maxContactCount: Int? = nil,
        requireLargeContactArea: Bool = false,
        minTotalContactArea: Double = 1.4,
        minAverageContactArea: Double = 0.14,
        requirePalmLikeContact: Bool = false,
        palmDetectionMode: WholeHandPalmDetectionMode = .disabledFallback,
        minTapMilliseconds: Int = 30,
        maxTapMilliseconds: Int = 700,
        maximumMovement: Double = 0.18,
        region: NormalizedRegion? = nil
    ) {
        self.nominalContactCount = nominalContactCount
        self.minContactCount = minContactCount
        self.maxContactCount = maxContactCount
        self.requireLargeContactArea = requireLargeContactArea
        self.minTotalContactArea = minTotalContactArea
        self.minAverageContactArea = minAverageContactArea
        self.requirePalmLikeContact = requirePalmLikeContact
        self.palmDetectionMode = palmDetectionMode
        self.minTapMilliseconds = minTapMilliseconds
        self.maxTapMilliseconds = maxTapMilliseconds
        self.maximumMovement = maximumMovement
        self.region = region
    }

    public func validate(name: String) throws {
        guard (6...16).contains(nominalContactCount), (5...16).contains(minContactCount) else {
            throw ConfigurationError.invalidValue("\(name).contact counts must be in a practical trackpad range.")
        }
        if let maxContactCount, maxContactCount < minContactCount {
            throw ConfigurationError.invalidValue("\(name).maxContactCount must be >= minContactCount.")
        }
        guard minTapMilliseconds >= 0, minTapMilliseconds <= maxTapMilliseconds,
              maxTapMilliseconds <= 2_000 else {
            throw ConfigurationError.invalidValue("\(name).tap timing is invalid.")
        }
        guard (0.0...0.8).contains(maximumMovement) else {
            throw ConfigurationError.invalidValue("\(name).maximumMovement must be 0.0...0.8.")
        }
        try region?.validate(name: "\(name).region")
    }
}
