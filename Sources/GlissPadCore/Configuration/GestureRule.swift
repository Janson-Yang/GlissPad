import Foundation

public enum GestureRule: Codable, Equatable, Sendable {
    case oneFinger(id: String, type: GestureTriggerType, rule: OneFingerGestureRule)
    case circle(id: String, type: GestureTriggerType, rule: CircleGestureRule)
    case shape(id: String, type: GestureTriggerType, rule: ShapeGestureRule)
    case cornerClick(id: String, type: GestureTriggerType, rule: CornerClickGestureRule)
    case tap(id: String, type: GestureTriggerType, rule: TapGestureRule)
    case oneFingerPress(id: String, type: GestureTriggerType, rule: OneFingerPressGestureRule)
    case customPath(id: String, type: GestureTriggerType, rule: CustomPathGestureRule)
    case touchStart(id: String, type: GestureTriggerType, rule: TouchStartGestureRule)
    case tipTap(id: String, type: GestureTriggerType, rule: TipTapGestureRule)
    case transform(id: String, type: GestureTriggerType, rule: TwoFingerTransformGestureRule)
    case multiFingerSwipe(id: String, type: GestureTriggerType, rule: MultiFingerSwipeGestureRule)
    case press(id: String, type: GestureTriggerType, rule: PressGestureRule)
    case swipe(id: String, type: GestureTriggerType, rule: SwipeGestureRule)
    case hold(id: String, type: GestureTriggerType, rule: HoldGestureRule)
    case release(id: String, type: GestureTriggerType, rule: ReleaseGestureRule)
    case threeFinger(id: String, type: GestureTriggerType, rule: ThreeFingerGestureRule)

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case oneFinger
        case circle
        case shape
        case cornerClick
        case tap
        case oneFingerPress
        case customPath
        case touchStart
        case tipTap
        case transform
        case multiFingerSwipe
        case press
        case swipe
        case hold
        case release
        case threeFinger
    }

    public var id: String {
        switch self {
        case .oneFinger(let id, _, _), .circle(let id, _, _), .cornerClick(let id, _, _),
             .shape(let id, _, _), .tap(let id, _, _), .oneFingerPress(let id, _, _), .customPath(let id, _, _),
             .touchStart(let id, _, _), .tipTap(let id, _, _), .transform(let id, _, _),
             .multiFingerSwipe(let id, _, _), .press(let id, _, _), .swipe(let id, _, _),
             .hold(let id, _, _), .release(let id, _, _), .threeFinger(let id, _, _):
            return id
        }
    }

    public var type: GestureTriggerType {
        switch self {
        case .oneFinger(_, let type, _), .circle(_, let type, _), .cornerClick(_, let type, _),
             .shape(_, let type, _), .tap(_, let type, _), .oneFingerPress(_, let type, _), .customPath(_, let type, _),
             .touchStart(_, let type, _), .tipTap(_, let type, _), .transform(_, let type, _),
             .multiFingerSwipe(_, let type, _), .press(_, let type, _), .swipe(_, let type, _),
             .hold(_, let type, _), .release(_, let type, _), .threeFinger(_, let type, _):
            return type
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GestureTriggerType.self, forKey: .type)
        let id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        switch type {
        case .oneFingerTouchStart:
            self = .oneFinger(id: id, type: type, rule: try container.decode(OneFingerGestureRule.self, forKey: .oneFinger))
        case .oneFingerCircle:
            self = .circle(id: id, type: type, rule: try container.decode(CircleGestureRule.self, forKey: .circle))
        case .oneFingerSquare, .oneFingerTriangle:
            self = .shape(id: id, type: type, rule: try container.decode(ShapeGestureRule.self, forKey: .shape))
        case .oneFingerCornerClick:
            self = .cornerClick(
                id: id,
                type: type,
                rule: try container.decode(CornerClickGestureRule.self, forKey: .cornerClick)
            )
        case .oneFingerTap, .oneFingerDoubleTap:
            self = .tap(id: id, type: type, rule: try container.decode(TapGestureRule.self, forKey: .tap))
        case .oneFingerPress:
            self = .oneFingerPress(
                id: id,
                type: type,
                rule: try container.decode(OneFingerPressGestureRule.self, forKey: .oneFingerPress)
            )
        case .oneFingerCustomPath, .oneFingerDrawnPath:
            self = .customPath(
                id: id,
                type: type,
                rule: try container.decode(CustomPathGestureRule.self, forKey: .customPath)
            )
        case .twoFingerTouchStart:
            self = .touchStart(id: id, type: type, rule: try container.decode(TouchStartGestureRule.self, forKey: .touchStart))
        case .tipTap:
            self = .tipTap(id: id, type: type, rule: try container.decode(TipTapGestureRule.self, forKey: .tipTap))
        case .pinchIn, .pinchOut, .rotateLeft, .rotateRight:
            self = .transform(
                id: id,
                type: type,
                rule: try container.decode(TwoFingerTransformGestureRule.self, forKey: .transform)
            )
        case .freeformTwoFingerSwipe, .regionTwoFingerSwipe:
            self = .multiFingerSwipe(
                id: id,
                type: type,
                rule: try container.decode(MultiFingerSwipeGestureRule.self, forKey: .multiFingerSwipe)
            )
        case .threeFingerForcePress, .upperLeftForcePress, .upperRightForcePress:
            self = .press(id: id, type: type, rule: try container.decode(PressGestureRule.self, forKey: .press))
        case .leftEdgeTwoFingerSwipe:
            self = .swipe(id: id, type: type, rule: try container.decode(SwipeGestureRule.self, forKey: .swipe))
        case .oneFingerLongPress, .twoFingerHold:
            self = .hold(id: id, type: type, rule: try container.decode(HoldGestureRule.self, forKey: .hold))
        case .twoFingerTap:
            self = .tap(id: id, type: type, rule: try container.decode(TapGestureRule.self, forKey: .tap))
        case .releaseLastFinger:
            self = .release(id: id, type: type, rule: try container.decode(ReleaseGestureRule.self, forKey: .release))
        case .threeFingerTouch, .threeFingerTap, .threeFingerPress, .threeFingerSwipe,
             .threeFingerTipTap, .threeFingerTipSwipe, .thumbTwoFingerScale, .threeFingerDrawing:
            self = .threeFinger(
                id: id,
                type: type,
                rule: try container.decode(ThreeFingerGestureRule.self, forKey: .threeFinger)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        switch self {
        case .oneFinger(_, _, let rule):
            try container.encode(rule, forKey: .oneFinger)
        case .circle(_, _, let rule):
            try container.encode(rule, forKey: .circle)
        case .shape(_, _, let rule):
            try container.encode(rule, forKey: .shape)
        case .cornerClick(_, _, let rule):
            try container.encode(rule, forKey: .cornerClick)
        case .tap(_, _, let rule):
            try container.encode(rule, forKey: .tap)
        case .oneFingerPress(_, _, let rule):
            try container.encode(rule, forKey: .oneFingerPress)
        case .customPath(_, _, let rule):
            try container.encode(rule, forKey: .customPath)
        case .touchStart(_, _, let rule):
            try container.encode(rule, forKey: .touchStart)
        case .tipTap(_, _, let rule):
            try container.encode(rule, forKey: .tipTap)
        case .transform(_, _, let rule):
            try container.encode(rule, forKey: .transform)
        case .multiFingerSwipe(_, _, let rule):
            try container.encode(rule, forKey: .multiFingerSwipe)
        case .press(_, _, let rule):
            try container.encode(rule, forKey: .press)
        case .swipe(_, _, let rule):
            try container.encode(rule, forKey: .swipe)
        case .hold(_, _, let rule):
            try container.encode(rule, forKey: .hold)
        case .release(_, _, let rule):
            try container.encode(rule, forKey: .release)
        case .threeFinger(_, _, let rule):
            try container.encode(rule, forKey: .threeFinger)
        }
    }

    public func validate(name: String) throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).id must not be empty.")
        }
        switch self {
        case .oneFinger(_, let type, let rule):
            guard type == .oneFingerTouchStart else {
                throw ConfigurationError.invalidValue("\(name) has mismatched one finger type.")
            }
            try rule.validate(name: "\(name).oneFinger")
        case .circle(_, let type, let rule):
            guard type == .oneFingerCircle else {
                throw ConfigurationError.invalidValue("\(name) has mismatched circle type.")
            }
            try rule.validate(name: "\(name).circle")
        case .shape(_, let type, let rule):
            guard [.oneFingerSquare, .oneFingerTriangle].contains(type),
                  (type == .oneFingerSquare && rule.shape == .square)
                    || (type == .oneFingerTriangle && rule.shape == .triangle) else {
                throw ConfigurationError.invalidValue("\(name) has mismatched shape type.")
            }
            try rule.validate(name: "\(name).shape")
        case .cornerClick(_, let type, let rule):
            guard type == .oneFingerCornerClick else {
                throw ConfigurationError.invalidValue("\(name) has mismatched corner click type.")
            }
            try rule.validate(name: "\(name).cornerClick")
        case .tap(_, let type, let rule):
            guard [.oneFingerTap, .oneFingerDoubleTap, .twoFingerTap].contains(type) else {
                throw ConfigurationError.invalidValue("\(name) has mismatched tap type.")
            }
            try rule.validate(name: "\(name).tap")
        case .oneFingerPress(_, let type, let rule):
            guard type == .oneFingerPress else {
                throw ConfigurationError.invalidValue("\(name) has mismatched one finger press type.")
            }
            try rule.validate(name: "\(name).oneFingerPress")
        case .customPath(_, let type, let rule):
            guard [.oneFingerCustomPath, .oneFingerDrawnPath].contains(type) else {
                throw ConfigurationError.invalidValue("\(name) has mismatched custom path type.")
            }
            try rule.validate(name: "\(name).customPath")
        case .touchStart(_, let type, let rule):
            guard type == .twoFingerTouchStart else {
                throw ConfigurationError.invalidValue("\(name) has mismatched touch start type.")
            }
            try rule.validate(name: "\(name).touchStart")
        case .tipTap(_, let type, let rule):
            guard type == .tipTap else {
                throw ConfigurationError.invalidValue("\(name) has mismatched tip tap type.")
            }
            try rule.validate(name: "\(name).tipTap")
        case .transform(_, let type, let rule):
            guard [.pinchIn, .pinchOut, .rotateLeft, .rotateRight].contains(type) else {
                throw ConfigurationError.invalidValue("\(name) has mismatched transform type.")
            }
            try rule.validate(name: "\(name).transform")
        case .multiFingerSwipe(_, let type, let rule):
            guard [.freeformTwoFingerSwipe, .regionTwoFingerSwipe].contains(type) else {
                throw ConfigurationError.invalidValue("\(name) has mismatched multi finger swipe type.")
            }
            if type == .regionTwoFingerSwipe, rule.startRegion == nil || rule.endRegion == nil {
                throw ConfigurationError.invalidValue("\(name).multiFingerSwipe requires start and end regions.")
            }
            try rule.validate(name: "\(name).multiFingerSwipe")
        case .press(_, let type, let rule):
            guard [.threeFingerForcePress, .upperLeftForcePress, .upperRightForcePress].contains(type) else {
                throw ConfigurationError.invalidValue("\(name) has mismatched press type.")
            }
            try rule.validate(name: "\(name).press")
        case .swipe(_, let type, let rule):
            guard type == .leftEdgeTwoFingerSwipe else {
                throw ConfigurationError.invalidValue("\(name) has mismatched swipe type.")
            }
            try rule.validate(name: "\(name).swipe")
        case .hold(_, let type, let rule):
            guard [.oneFingerLongPress, .twoFingerHold].contains(type) else {
                throw ConfigurationError.invalidValue("\(name) has mismatched hold type.")
            }
            try rule.validate(name: "\(name).hold")
        case .release(_, let type, let rule):
            guard type == .releaseLastFinger else {
                throw ConfigurationError.invalidValue("\(name) has mismatched release type.")
            }
            try rule.validate(name: "\(name).release")
        case .threeFinger(_, let type, let rule):
            try rule.validate(name: "\(name).threeFinger", type: type)
        }
    }

}
