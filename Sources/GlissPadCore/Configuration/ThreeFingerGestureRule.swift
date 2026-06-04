import Foundation

public struct ThreeFingerGestureRule: Codable, Equatable, Sendable {
    public var name: String
    public var isEnabled: Bool
    public var common: ThreeFingerCommonOptions
    public var touch: ThreeFingerTouchOptions
    public var tap: ThreeFingerTapOptions
    public var press: ThreeFingerPressOptions
    public var swipe: ThreeFingerSwipeOptions
    public var tipTap: ThreeFingerTipTapOptions
    public var tipSwipe: ThreeFingerTipSwipeOptions
    public var scale: ThreeFingerScaleOptions
    public var drawing: ThreeFingerDrawingOptions
    public var cooldownMilliseconds: Int
    public var actions: [GestureAction]

    public init(
        name: String,
        isEnabled: Bool,
        common: ThreeFingerCommonOptions = ThreeFingerCommonOptions(),
        touch: ThreeFingerTouchOptions = ThreeFingerTouchOptions(),
        tap: ThreeFingerTapOptions = ThreeFingerTapOptions(),
        press: ThreeFingerPressOptions = ThreeFingerPressOptions(),
        swipe: ThreeFingerSwipeOptions = ThreeFingerSwipeOptions(),
        tipTap: ThreeFingerTipTapOptions = ThreeFingerTipTapOptions(),
        tipSwipe: ThreeFingerTipSwipeOptions = ThreeFingerTipSwipeOptions(),
        scale: ThreeFingerScaleOptions = ThreeFingerScaleOptions(),
        drawing: ThreeFingerDrawingOptions = ThreeFingerDrawingOptions(),
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
        self.tipTap = tipTap
        self.tipSwipe = tipSwipe
        self.scale = scale
        self.drawing = drawing
        self.cooldownMilliseconds = cooldownMilliseconds
        self.actions = GestureActionsCoding.resolvedDefaultNames(actions)
    }

    public init(
        name: String,
        isEnabled: Bool,
        cooldownMilliseconds: Int,
        action: ScriptAction
    ) {
        self.init(
            name: name,
            isEnabled: isEnabled,
            cooldownMilliseconds: cooldownMilliseconds,
            actions: [.script(action)]
        )
    }

    public func validate(name: String, type: GestureTriggerType) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard type.isThreeFingerGestureFamily else {
            throw ConfigurationError.invalidValue("\(name) has mismatched three finger type.")
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

    private func validateFamilyOptions(name: String, type: GestureTriggerType) throws {
        switch type {
        case .threeFingerTouch:
            try touch.validate(name: "\(name).touch")
        case .threeFingerTap:
            try tap.validate(name: "\(name).tap")
        case .threeFingerPress:
            try press.validate(name: "\(name).press")
        case .threeFingerSwipe:
            try swipe.validate(name: "\(name).swipe")
        case .threeFingerTipTap:
            try tipTap.validate(name: "\(name).tipTap")
        case .threeFingerTipSwipe:
            try tipSwipe.validate(name: "\(name).tipSwipe")
        case .thumbTwoFingerScale:
            try scale.validate(name: "\(name).scale")
        case .threeFingerDrawing:
            try drawing.validate(name: "\(name).drawing")
        default:
            break
        }
    }
}

public extension GestureTriggerType {
    var isThreeFingerGestureFamily: Bool {
        switch self {
        case .threeFingerTouch, .threeFingerTap, .threeFingerPress, .threeFingerSwipe,
             .threeFingerTipTap, .threeFingerTipSwipe, .thumbTwoFingerScale, .threeFingerDrawing:
            return true
        default:
            return false
        }
    }
}

