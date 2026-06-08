import Foundation

public struct FourFingerGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var common: ThreeFingerCommonOptions
    public var touch: ThreeFingerTouchOptions
    public var tap: ThreeFingerTapOptions
    public var press: FourFingerPressOptions
    public var swipe: ThreeFingerSwipeOptions
    public var scale: ThreeFingerScaleOptions
    public var tipTap: FourFingerTipTapOptions
    public var drawing: ThreeFingerDrawingOptions
    public var cooldownMilliseconds: Int
    public var actions: [GestureAction]

    public init(
        name: String,
        isEnabled: Bool,
        common: ThreeFingerCommonOptions = FourFingerGestureRule.defaultCommonOptions(),
        touch: ThreeFingerTouchOptions = ThreeFingerTouchOptions(),
        tap: ThreeFingerTapOptions = ThreeFingerTapOptions(maximumMovement: 0.06),
        press: FourFingerPressOptions = FourFingerPressOptions(),
        swipe: ThreeFingerSwipeOptions = FourFingerGestureRule.defaultSwipeOptions(),
        scale: ThreeFingerScaleOptions = FourFingerGestureRule.defaultScaleOptions(),
        tipTap: FourFingerTipTapOptions = FourFingerTipTapOptions(),
        drawing: ThreeFingerDrawingOptions = FourFingerGestureRule.defaultDrawingOptions(),
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
        self.tipTap = tipTap
        self.drawing = drawing
        self.cooldownMilliseconds = cooldownMilliseconds
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public func validate(name: String, type: GestureTriggerType) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard type.isFourFingerGestureFamily else {
            throw ConfigurationError.invalidValue("\(name) has mismatched four finger type.")
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
            common: common,
            touch: touch,
            tap: tap,
            press: press.threeFingerPressOptions(),
            swipe: swipe,
            tipTap: tipTap.threeFingerTipTapOptions(),
            scale: scale,
            drawing: drawing,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: actions
        )
    }

    public static func defaultCommonOptions() -> ThreeFingerCommonOptions {
        ThreeFingerCommonOptions(
            maxInitialFingerTimeGapMilliseconds: 90,
            minStableFingerCountDurationMilliseconds: 35
        )
    }

    public static func defaultSwipeOptions() -> ThreeFingerSwipeOptions {
        ThreeFingerSwipeOptions(direction: .right, minimumTravel: 0.20, minimumVelocity: 0.9)
    }

    public static func defaultScaleOptions() -> ThreeFingerScaleOptions {
        ThreeFingerScaleOptions(direction: .spreadOut, thumbDetectionMode: .disabledFallback)
    }

    public static func defaultDrawingOptions() -> ThreeFingerDrawingOptions {
        ThreeFingerDrawingOptions(minimumPathLength: 0.28)
    }

    private func validateFamilyOptions(name: String, type: GestureTriggerType) throws {
        switch type {
        case .fourFingerTouch:
            try touch.validate(name: "\(name).touch")
        case .fourFingerTap:
            try tap.validate(name: "\(name).tap")
        case .fourFingerPress:
            try press.validate(name: "\(name).press")
        case .fourFingerSwipe:
            try swipe.validate(name: "\(name).swipe")
        case .thumbThreeFingerScale:
            try scale.validate(name: "\(name).scale")
        case .fourFingerTipTap:
            try tipTap.validate(name: "\(name).tipTap")
        case .fourFingerDrawing:
            try drawing.validate(name: "\(name).drawing")
        default:
            break
        }
    }
}

extension FourFingerPressOptions {
    func threeFingerPressOptions() -> ThreeFingerPressOptions {
        ThreeFingerPressOptions(
            level: level,
            pressureBias: .none,
            minimumPressure: minimumPressure,
            forcePressure: forcePressure,
            triggerTiming: triggerTiming,
            allowFallbackWithoutPressureData: allowFallbackWithoutPressureData
        )
    }
}

extension FourFingerTipTapOptions {
    func threeFingerTipTapOptions() -> ThreeFingerTipTapOptions {
        ThreeFingerTipTapOptions(
            fixedFingers: fixedFingers,
            tapPosition: tapSide.threeFingerActiveFinger,
            positionReference: sideReference.threeFingerReference,
            tapCount: tapCount,
            maximumTapMilliseconds: maximumTapMilliseconds,
            maximumActiveFingerMovement: maximumActiveFingerMovement,
            maximumFixedFingerMovement: maximumFixedFingerMovement,
            minimumFixedFingerHoldMilliseconds: requireFixedFingersAlreadyDown
                ? minimumFixedFingerHoldMilliseconds
                : 0
        )
    }
}

extension FourFingerTipTapSide {
    var threeFingerActiveFinger: ThreeFingerActiveFinger {
        switch self {
        case .auto: return .auto
        case .left: return .left
        case .right: return .right
        }
    }
}

extension FourFingerTipTapSideReference {
    var threeFingerReference: ThreeFingerFingerReference {
        switch self {
        case .relativeToFixedGroup: return .relativeToFixedGroup
        case .touchOrder: return .touchOrder
        case .trackpad: return .trackpad
        }
    }
}

public extension GestureTriggerType {
    var isFourFingerGestureFamily: Bool {
        switch self {
        case .fourFingerTouch, .fourFingerTap, .fourFingerPress, .fourFingerSwipe,
             .thumbThreeFingerScale, .fourFingerTipTap, .fourFingerDrawing:
            return true
        default:
            return false
        }
    }
}
