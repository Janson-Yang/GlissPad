import Foundation

public struct FiveAndMoreFingerGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var common: ThreeFingerCommonOptions
    public var touch: FiveFingerTouchOptions
    public var tap: ThreeFingerTapOptions
    public var press: FourFingerPressOptions
    public var swipe: ThreeFingerSwipeOptions
    public var scale: ThreeFingerScaleOptions
    public var drawing: ThreeFingerDrawingOptions
    public var wholeHandTap: WholeHandTapOptions
    public var cooldownMilliseconds: Int
    public var actions: [GestureAction]

    public init(
        name: String,
        isEnabled: Bool,
        common: ThreeFingerCommonOptions = FiveAndMoreFingerGestureRule.defaultCommonOptions(),
        touch: FiveFingerTouchOptions = FiveFingerTouchOptions(),
        tap: ThreeFingerTapOptions = FiveAndMoreFingerGestureRule.defaultTapOptions(),
        press: FourFingerPressOptions = FourFingerPressOptions(),
        swipe: ThreeFingerSwipeOptions = FiveAndMoreFingerGestureRule.defaultSwipeOptions(),
        scale: ThreeFingerScaleOptions = FiveAndMoreFingerGestureRule.defaultScaleOptions(),
        drawing: ThreeFingerDrawingOptions = FiveAndMoreFingerGestureRule.defaultDrawingOptions(),
        wholeHandTap: WholeHandTapOptions = WholeHandTapOptions(),
        cooldownMilliseconds: Int,
        actions: [GestureAction]
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.common = common
        self.touch = touch
        self.tap = tap
        self.press = press
        self.swipe = swipe
        self.scale = scale
        self.drawing = drawing
        self.wholeHandTap = wholeHandTap
        self.cooldownMilliseconds = cooldownMilliseconds
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public func validate(name: String, type: GestureTriggerType) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard type.isFiveAndMoreFingerGestureFamily else {
            throw ConfigurationError.invalidValue("\(name) has mismatched five and more finger type.")
        }
        guard (100...10_000).contains(cooldownMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).cooldownMilliseconds must be 100...10000.")
        }
        try common.validate(name: "\(name).common")
        try validateFamilyOptions(name: name, type: type)
        for (index, action) in actions.enumerated() {
            try action.validate(name: "\(name).actions[\(index)]")
        }
    }

    public func recognitionRule() -> ThreeFingerGestureRule {
        ThreeFingerGestureRule(
            name: name,
            isEnabled: isEnabled,
            common: recognitionCommon(),
            touch: touch.threeFingerTouchOptions(),
            tap: tap,
            press: press.threeFingerPressOptions(),
            swipe: swipe,
            scale: scale,
            drawing: drawing,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: actions
        )
    }

    public static func defaultCommonOptions() -> ThreeFingerCommonOptions {
        ThreeFingerCommonOptions(maxInitialFingerTimeGapMilliseconds: 100, minStableFingerCountDurationMilliseconds: 40)
    }

    public static func defaultTapOptions() -> ThreeFingerTapOptions {
        ThreeFingerTapOptions(maximumTapMilliseconds: 320, maximumMovement: 0.10, maximumInterTapIntervalMilliseconds: 320)
    }

    public static func defaultSwipeOptions() -> ThreeFingerSwipeOptions {
        ThreeFingerSwipeOptions(direction: .right, minimumTravel: 0.22, minimumVelocity: 0.75)
    }

    public static func defaultScaleOptions() -> ThreeFingerScaleOptions {
        ThreeFingerScaleOptions(direction: .spreadOut, minimumScaleDelta: 0.16, thumbDetectionMode: .heuristic)
    }

    public static func defaultDrawingOptions() -> ThreeFingerDrawingOptions {
        ThreeFingerDrawingOptions(minimumPathLength: 0.30)
    }

    private func recognitionCommon() -> ThreeFingerCommonOptions {
        var adjusted = common
        if touch.event == .stableTouch {
            adjusted.minStableFingerCountDurationMilliseconds = touch.stableMilliseconds
        }
        return adjusted
    }

    private func validateFamilyOptions(name: String, type: GestureTriggerType) throws {
        switch type {
        case .fiveFingerTouch:
            try touch.validate(name: "\(name).touch")
        case .fiveFingerTap:
            try tap.validate(name: "\(name).tap")
        case .fiveFingerPress:
            try press.validate(name: "\(name).press")
        case .fiveFingerSwipe:
            try swipe.validate(name: "\(name).swipe")
        case .thumbFourFingerScale:
            try scale.validate(name: "\(name).scale")
        case .fiveFingerDrawing:
            try drawing.validate(name: "\(name).drawing")
        case .wholeHandTap:
            try wholeHandTap.validate(name: "\(name).wholeHandTap")
        default:
            break
        }
    }
}

extension FiveFingerTouchOptions {
    func threeFingerTouchOptions() -> ThreeFingerTouchOptions {
        ThreeFingerTouchOptions(
            event: threeFingerEvent,
            holdMilliseconds: holdMilliseconds,
            movementTolerance: movementTolerance,
            cancelOnMovement: cancelOnMovement,
            cancelOnPress: cancelOnPress,
            repeatWhileHolding: repeatWhileHolding,
            repeatIntervalMilliseconds: repeatIntervalMilliseconds,
            triggerTiming: triggerTiming
        )
    }

    private var threeFingerEvent: ThreeFingerTouchEvent {
        switch event {
        case .touchStart, .stableTouch: return .touchStart
        case .longTouch: return .longTouch
        case .touchEnd: return .touchEnd
        }
    }
}

public extension GestureTriggerType {
    var isFiveAndMoreFingerGestureFamily: Bool {
        switch self {
        case .fiveFingerTouch, .fiveFingerTap, .fiveFingerPress, .thumbFourFingerScale,
             .fiveFingerSwipe, .fiveFingerDrawing, .wholeHandTap:
            return true
        default:
            return false
        }
    }
}
