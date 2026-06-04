import Foundation

public struct ThreeFingerCommonOptions: Codable, Equatable, Sendable {
    public var region: NormalizedRegion?
    public var startRegion: NormalizedRegion?
    public var endRegion: NormalizedRegion?
    public var maxInitialFingerTimeGapMilliseconds: Int
    public var minStableFingerCountDurationMilliseconds: Int

    public init(
        region: NormalizedRegion? = nil,
        startRegion: NormalizedRegion? = nil,
        endRegion: NormalizedRegion? = nil,
        maxInitialFingerTimeGapMilliseconds: Int = 80,
        minStableFingerCountDurationMilliseconds: Int = 30
    ) {
        self.region = region
        self.startRegion = startRegion
        self.endRegion = endRegion
        self.maxInitialFingerTimeGapMilliseconds = maxInitialFingerTimeGapMilliseconds
        self.minStableFingerCountDurationMilliseconds = minStableFingerCountDurationMilliseconds
    }

    public func validate(name: String) throws {
        try region?.validate(name: "\(name).region")
        try startRegion?.validate(name: "\(name).startRegion")
        try endRegion?.validate(name: "\(name).endRegion")
        guard (0...500).contains(maxInitialFingerTimeGapMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).maxInitialFingerTimeGapMilliseconds must be 0...500.")
        }
        guard (0...500).contains(minStableFingerCountDurationMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).minStableFingerCountDurationMilliseconds must be 0...500.")
        }
    }
}

public struct ThreeFingerTouchOptions: Codable, Equatable, Sendable {
    public var event: ThreeFingerTouchEvent
    public var holdMilliseconds: Int
    public var movementTolerance: Double
    public var cancelOnMovement: Bool
    public var cancelOnPress: Bool
    public var repeatWhileHolding: Bool
    public var repeatIntervalMilliseconds: Int
    public var triggerTiming: ThreeFingerTriggerTiming

    public init(
        event: ThreeFingerTouchEvent = .touchStart,
        holdMilliseconds: Int = 500,
        movementTolerance: Double = 0.08,
        cancelOnMovement: Bool = true,
        cancelOnPress: Bool = true,
        repeatWhileHolding: Bool = false,
        repeatIntervalMilliseconds: Int = 300,
        triggerTiming: ThreeFingerTriggerTiming = .thresholdReached
    ) {
        self.event = event
        self.holdMilliseconds = holdMilliseconds
        self.movementTolerance = movementTolerance
        self.cancelOnMovement = cancelOnMovement
        self.cancelOnPress = cancelOnPress
        self.repeatWhileHolding = repeatWhileHolding
        self.repeatIntervalMilliseconds = repeatIntervalMilliseconds
        self.triggerTiming = triggerTiming
    }

    public func validate(name: String) throws {
        try Self.validate(milliseconds: holdMilliseconds, name: "\(name).holdMilliseconds", lowerBound: 100)
        try Self.validate(milliseconds: repeatIntervalMilliseconds, name: "\(name).repeatIntervalMilliseconds", lowerBound: 50)
        guard (0.0...0.5).contains(movementTolerance) else {
            throw ConfigurationError.invalidValue("\(name).movementTolerance must be 0.0...0.5.")
        }
    }
}

public struct ThreeFingerTapOptions: Codable, Equatable, Sendable {
    public var tapCount: Int
    public var maximumTapMilliseconds: Int
    public var maximumMovement: Double
    public var maximumInterTapIntervalMilliseconds: Int
    public var requireNoPress: Bool

    public init(
        tapCount: Int = 1,
        maximumTapMilliseconds: Int = 180,
        maximumMovement: Double = 0.05,
        maximumInterTapIntervalMilliseconds: Int = 250,
        requireNoPress: Bool = true
    ) {
        self.tapCount = tapCount
        self.maximumTapMilliseconds = maximumTapMilliseconds
        self.maximumMovement = maximumMovement
        self.maximumInterTapIntervalMilliseconds = maximumInterTapIntervalMilliseconds
        self.requireNoPress = requireNoPress
    }

    public func validate(name: String) throws {
        guard [1, 2, 3].contains(tapCount) else {
            throw ConfigurationError.invalidValue("\(name).tapCount must be 1, 2, or 3.")
        }
        try Self.validate(milliseconds: maximumTapMilliseconds, name: "\(name).maximumTapMilliseconds", lowerBound: 50)
        try Self.validate(milliseconds: maximumInterTapIntervalMilliseconds, name: "\(name).maximumInterTapIntervalMilliseconds", lowerBound: 50)
        guard (0.0...0.5).contains(maximumMovement) else {
            throw ConfigurationError.invalidValue("\(name).maximumMovement must be 0.0...0.5.")
        }
    }
}

public struct ThreeFingerPressOptions: Codable, Equatable, Sendable {
    public var level: ThreeFingerPressLevel
    public var pressureBias: ThreeFingerPressureBias
    public var minimumPressure: Double
    public var forcePressure: Double
    public var pressureBiasThreshold: Double
    public var triggerTiming: ThreeFingerPressTriggerTiming
    public var allowFallbackWithoutPressureData: Bool

    public init(
        level: ThreeFingerPressLevel = .force,
        pressureBias: ThreeFingerPressureBias = .none,
        minimumPressure: Double = TrackpadPressureThreshold.click,
        forcePressure: Double = TrackpadPressureThreshold.forceClick,
        pressureBiasThreshold: Double = 0.18,
        triggerTiming: ThreeFingerPressTriggerTiming = .pressDown,
        allowFallbackWithoutPressureData: Bool = false
    ) {
        self.level = level
        self.pressureBias = pressureBias
        self.minimumPressure = minimumPressure
        self.forcePressure = forcePressure
        self.pressureBiasThreshold = pressureBiasThreshold
        self.triggerTiming = triggerTiming
        self.allowFallbackWithoutPressureData = allowFallbackWithoutPressureData
    }

    public func validate(name: String) throws {
        guard (0.0...1.5).contains(minimumPressure), (0.0...1.5).contains(forcePressure) else {
            throw ConfigurationError.invalidValue("\(name).pressure thresholds must be 0.0...1.5.")
        }
        guard (0.0...1.0).contains(pressureBiasThreshold) else {
            throw ConfigurationError.invalidValue("\(name).pressureBiasThreshold must be 0.0...1.0.")
        }
    }
}

extension ThreeFingerTouchOptions {
    static func validate(milliseconds: Int, name: String, lowerBound: Int) throws {
        guard (lowerBound...10_000).contains(milliseconds) else {
            throw ConfigurationError.invalidValue("\(name) must be \(lowerBound)...10000.")
        }
    }
}

extension ThreeFingerTapOptions {
    static func validate(milliseconds: Int, name: String, lowerBound: Int) throws {
        try ThreeFingerTouchOptions.validate(milliseconds: milliseconds, name: name, lowerBound: lowerBound)
    }
}
