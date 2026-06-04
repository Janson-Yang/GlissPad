import Foundation

public struct ThreeFingerSwipeOptions: Codable, Equatable, Sendable {
    public var direction: ThreeFingerDirection
    public var pressMode: ThreeFingerSwipePressMode
    public var minimumTravel: Double
    public var minimumVelocity: Double
    public var directionToleranceDegrees: Double
    public var triggerTiming: ThreeFingerTriggerTiming

    public init(
        direction: ThreeFingerDirection = .right,
        pressMode: ThreeFingerSwipePressMode = .none,
        minimumTravel: Double = 0.18,
        minimumVelocity: Double = 0.9,
        directionToleranceDegrees: Double = 35,
        triggerTiming: ThreeFingerTriggerTiming = .thresholdReached
    ) {
        self.direction = direction
        self.pressMode = pressMode
        self.minimumTravel = minimumTravel
        self.minimumVelocity = minimumVelocity
        self.directionToleranceDegrees = directionToleranceDegrees
        self.triggerTiming = triggerTiming
    }

    public func validate(name: String) throws {
        try validateDistance(minimumTravel, name: "\(name).minimumTravel", max: 1.2)
        guard (0.0...10.0).contains(minimumVelocity) else {
            throw ConfigurationError.invalidValue("\(name).minimumVelocity must be 0.0...10.0.")
        }
        guard (0...90).contains(directionToleranceDegrees) else {
            throw ConfigurationError.invalidValue("\(name).directionToleranceDegrees must be 0...90.")
        }
    }
}

public struct ThreeFingerTipTapOptions: Codable, Equatable, Sendable {
    public var fixedFingers: Int
    public var tapPosition: ThreeFingerActiveFinger
    public var positionReference: ThreeFingerFingerReference
    public var tapCount: Int
    public var maximumTapMilliseconds: Int
    public var maximumActiveFingerMovement: Double
    public var maximumFixedFingerMovement: Double
    public var minimumFixedFingerHoldMilliseconds: Int

    public init(
        fixedFingers: Int = 2,
        tapPosition: ThreeFingerActiveFinger = .auto,
        positionReference: ThreeFingerFingerReference = .trackpad,
        tapCount: Int = 1,
        maximumTapMilliseconds: Int = 180,
        maximumActiveFingerMovement: Double = 0.05,
        maximumFixedFingerMovement: Double = 0.03,
        minimumFixedFingerHoldMilliseconds: Int = 50
    ) {
        self.fixedFingers = fixedFingers
        self.tapPosition = tapPosition
        self.positionReference = positionReference
        self.tapCount = tapCount
        self.maximumTapMilliseconds = maximumTapMilliseconds
        self.maximumActiveFingerMovement = maximumActiveFingerMovement
        self.maximumFixedFingerMovement = maximumFixedFingerMovement
        self.minimumFixedFingerHoldMilliseconds = minimumFixedFingerHoldMilliseconds
    }

    public func validate(name: String) throws {
        guard fixedFingers == 2 else {
            throw ConfigurationError.invalidValue("\(name).fixedFingers must be 2.")
        }
        guard [1, 2].contains(tapCount) else {
            throw ConfigurationError.invalidValue("\(name).tapCount must be 1 or 2.")
        }
        try ThreeFingerTouchOptions.validate(milliseconds: maximumTapMilliseconds, name: "\(name).maximumTapMilliseconds", lowerBound: 50)
        try ThreeFingerTouchOptions.validate(milliseconds: minimumFixedFingerHoldMilliseconds, name: "\(name).minimumFixedFingerHoldMilliseconds", lowerBound: 0)
        try validateMovement(maximumActiveFingerMovement, name: "\(name).maximumActiveFingerMovement")
        try validateMovement(maximumFixedFingerMovement, name: "\(name).maximumFixedFingerMovement")
    }
}

public struct ThreeFingerTipSwipeOptions: Codable, Equatable, Sendable {
    public var fixedFingers: Int
    public var activeFinger: ThreeFingerActiveFinger
    public var activeFingerReference: ThreeFingerFingerReference
    public var direction: ThreeFingerDirection
    public var minimumTravel: Double
    public var minimumVelocity: Double
    public var directionToleranceDegrees: Double
    public var maximumFixedFingerMovement: Double
    public var minimumFixedFingerHoldMilliseconds: Int
    public var triggerTiming: ThreeFingerTriggerTiming

    public init(
        fixedFingers: Int = 2,
        activeFinger: ThreeFingerActiveFinger = .auto,
        activeFingerReference: ThreeFingerFingerReference = .trackpad,
        direction: ThreeFingerDirection = .up,
        minimumTravel: Double = 0.12,
        minimumVelocity: Double = 0.35,
        directionToleranceDegrees: Double = 35,
        maximumFixedFingerMovement: Double = 0.04,
        minimumFixedFingerHoldMilliseconds: Int = 50,
        triggerTiming: ThreeFingerTriggerTiming = .thresholdReached
    ) {
        self.fixedFingers = fixedFingers
        self.activeFinger = activeFinger
        self.activeFingerReference = activeFingerReference
        self.direction = direction
        self.minimumTravel = minimumTravel
        self.minimumVelocity = minimumVelocity
        self.directionToleranceDegrees = directionToleranceDegrees
        self.maximumFixedFingerMovement = maximumFixedFingerMovement
        self.minimumFixedFingerHoldMilliseconds = minimumFixedFingerHoldMilliseconds
        self.triggerTiming = triggerTiming
    }

    public func validate(name: String) throws {
        guard [1, 2].contains(fixedFingers) else {
            throw ConfigurationError.invalidValue("\(name).fixedFingers must be 1 or 2.")
        }
        guard fixedFingers == 2 || activeFinger != .middle else {
            throw ConfigurationError.invalidValue("\(name).activeFinger middle requires 2 fixed fingers.")
        }
        try validateDistance(minimumTravel, name: "\(name).minimumTravel", max: 1.2)
        try validateMovement(maximumFixedFingerMovement, name: "\(name).maximumFixedFingerMovement")
        guard (0.0...10.0).contains(minimumVelocity), (0...90).contains(directionToleranceDegrees) else {
            throw ConfigurationError.invalidValue("\(name).velocity or direction tolerance is out of range.")
        }
        try ThreeFingerTouchOptions.validate(milliseconds: minimumFixedFingerHoldMilliseconds, name: "\(name).minimumFixedFingerHoldMilliseconds", lowerBound: 0)
    }
}

func validateMovement(_ value: Double, name: String) throws {
    guard (0.0...0.5).contains(value) else {
        throw ConfigurationError.invalidValue("\(name) must be 0.0...0.5.")
    }
}

func validateDistance(_ value: Double, name: String, max: Double) throws {
    guard (0.0...max).contains(value) else {
        throw ConfigurationError.invalidValue("\(name) must be 0.0...\(max).")
    }
}
