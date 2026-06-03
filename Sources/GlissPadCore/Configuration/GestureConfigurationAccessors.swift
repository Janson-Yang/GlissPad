import Foundation

public extension GestureConfiguration {
    var oneFingerTouchStart: OneFingerGestureRule {
        get { oneFingerRule(for: .oneFingerTouchStart) ?? defaultRule(.oneFingerTouchStart) }
        set { upsert(.oneFinger(id: existingID(for: .oneFingerTouchStart), type: .oneFingerTouchStart, rule: newValue)) }
    }

    var oneFingerLongPress: HoldGestureRule {
        get { holdRule(for: .oneFingerLongPress) ?? defaultRule(.oneFingerLongPress) }
        set { upsert(.hold(id: existingID(for: .oneFingerLongPress), type: .oneFingerLongPress, rule: newValue)) }
    }

    var oneFingerCircle: CircleGestureRule {
        get { circleRule(for: .oneFingerCircle) ?? defaultRule(.oneFingerCircle) }
        set { upsert(.circle(id: existingID(for: .oneFingerCircle), type: .oneFingerCircle, rule: newValue)) }
    }

    var oneFingerSquare: ShapeGestureRule {
        get { shapeRule(for: .oneFingerSquare) ?? defaultRule(.oneFingerSquare) }
        set { upsert(.shape(id: existingID(for: .oneFingerSquare), type: .oneFingerSquare, rule: newValue)) }
    }

    var oneFingerTriangle: ShapeGestureRule {
        get { shapeRule(for: .oneFingerTriangle) ?? defaultRule(.oneFingerTriangle) }
        set { upsert(.shape(id: existingID(for: .oneFingerTriangle), type: .oneFingerTriangle, rule: newValue)) }
    }

    var oneFingerCornerClick: CornerClickGestureRule {
        get { cornerClickRule(for: .oneFingerCornerClick) ?? defaultRule(.oneFingerCornerClick) }
        set {
            upsert(.cornerClick(
                id: existingID(for: .oneFingerCornerClick),
                type: .oneFingerCornerClick,
                rule: newValue
            ))
        }
    }

    var oneFingerTap: TapGestureRule {
        get { tapRule(for: .oneFingerTap) ?? defaultRule(.oneFingerTap) }
        set { upsert(.tap(id: existingID(for: .oneFingerTap), type: .oneFingerTap, rule: newValue)) }
    }

    var oneFingerDoubleTap: TapGestureRule {
        get { tapRule(for: .oneFingerDoubleTap) ?? defaultRule(.oneFingerDoubleTap) }
        set { upsert(.tap(id: existingID(for: .oneFingerDoubleTap), type: .oneFingerDoubleTap, rule: newValue)) }
    }

    var oneFingerPress: OneFingerPressGestureRule {
        get { oneFingerPressRule(for: .oneFingerPress) ?? defaultRule(.oneFingerPress) }
        set { upsert(.oneFingerPress(id: existingID(for: .oneFingerPress), type: .oneFingerPress, rule: newValue)) }
    }

    var oneFingerCustomPath: CustomPathGestureRule {
        get { customPathRule(for: .oneFingerCustomPath) ?? defaultRule(.oneFingerCustomPath) }
        set { upsert(.customPath(id: existingID(for: .oneFingerCustomPath), type: .oneFingerCustomPath, rule: newValue)) }
    }

    var oneFingerDrawnPath: CustomPathGestureRule {
        get { customPathRule(for: .oneFingerDrawnPath) ?? defaultRule(.oneFingerDrawnPath) }
        set { upsert(.customPath(id: existingID(for: .oneFingerDrawnPath), type: .oneFingerDrawnPath, rule: newValue)) }
    }

    var threeFingerForcePress: PressGestureRule {
        get { pressRule(for: .threeFingerForcePress) ?? defaultRule(.threeFingerForcePress) }
        set { upsert(.press(id: existingID(for: .threeFingerForcePress), type: .threeFingerForcePress, rule: newValue)) }
    }

    var upperLeftForcePress: PressGestureRule {
        get { pressRule(for: .upperLeftForcePress) ?? defaultRule(.upperLeftForcePress) }
        set { upsert(.press(id: existingID(for: .upperLeftForcePress), type: .upperLeftForcePress, rule: newValue)) }
    }

    var leftEdgeTwoFingerSwipe: SwipeGestureRule {
        get { swipeRule(for: .leftEdgeTwoFingerSwipe) ?? defaultRule(.leftEdgeTwoFingerSwipe) }
        set { upsert(.swipe(id: existingID(for: .leftEdgeTwoFingerSwipe), type: .leftEdgeTwoFingerSwipe, rule: newValue)) }
    }

    var twoFingerHold: HoldGestureRule {
        get { holdRule(for: .twoFingerHold) ?? defaultRule(.twoFingerHold) }
        set { upsert(.hold(id: existingID(for: .twoFingerHold), type: .twoFingerHold, rule: newValue)) }
    }

    var upperRightForcePress: PressGestureRule {
        get { pressRule(for: .upperRightForcePress) ?? defaultRule(.upperRightForcePress) }
        set { upsert(.press(id: existingID(for: .upperRightForcePress), type: .upperRightForcePress, rule: newValue)) }
    }

    var releaseLastFinger: ReleaseGestureRule {
        get { releaseRule(for: .releaseLastFinger) ?? defaultRule(.releaseLastFinger) }
        set { upsert(.release(id: existingID(for: .releaseLastFinger), type: .releaseLastFinger, rule: newValue)) }
    }
}

private extension GestureConfiguration {
    func oneFingerRule(for type: GestureTriggerType) -> OneFingerGestureRule? {
        guard case .oneFinger(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func circleRule(for type: GestureTriggerType) -> CircleGestureRule? {
        guard case .circle(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func shapeRule(for type: GestureTriggerType) -> ShapeGestureRule? {
        guard case .shape(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func cornerClickRule(for type: GestureTriggerType) -> CornerClickGestureRule? {
        guard case .cornerClick(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func tapRule(for type: GestureTriggerType) -> TapGestureRule? {
        guard case .tap(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func oneFingerPressRule(for type: GestureTriggerType) -> OneFingerPressGestureRule? {
        guard case .oneFingerPress(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func customPathRule(for type: GestureTriggerType) -> CustomPathGestureRule? {
        guard case .customPath(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func pressRule(for type: GestureTriggerType) -> PressGestureRule? {
        guard case .press(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func swipeRule(for type: GestureTriggerType) -> SwipeGestureRule? {
        guard case .swipe(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func holdRule(for type: GestureTriggerType) -> HoldGestureRule? {
        guard case .hold(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    func releaseRule(for type: GestureTriggerType) -> ReleaseGestureRule? {
        guard case .release(_, _, let rule)? = triggers.first(where: { $0.type == type }) else { return nil }
        return rule
    }

    mutating func upsert(_ trigger: GestureRule) {
        guard let index = triggers.firstIndex(where: { $0.type == trigger.type }) else {
            triggers.append(trigger)
            return
        }
        triggers[index] = trigger
    }

    func existingID(for type: GestureTriggerType) -> String {
        triggers.first(where: { $0.type == type })?.id ?? type.defaultID
    }

    func defaultRule(_ type: GestureTriggerType) -> PressGestureRule {
        guard case .press(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected press default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> OneFingerGestureRule {
        guard case .oneFinger(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected one finger default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> CircleGestureRule {
        guard case .circle(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected circle default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> ShapeGestureRule {
        guard case .shape(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected shape default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> CornerClickGestureRule {
        guard case .cornerClick(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected corner click default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> TapGestureRule {
        guard case .tap(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected tap default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> OneFingerPressGestureRule {
        guard case .oneFingerPress(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected one finger press default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> CustomPathGestureRule {
        guard case .customPath(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected custom path default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> SwipeGestureRule {
        guard case .swipe(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected swipe default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> HoldGestureRule {
        guard case .hold(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected hold default")
        }
        return rule
    }

    func defaultRule(_ type: GestureTriggerType) -> ReleaseGestureRule {
        guard case .release(_, _, let rule) = type.defaultTrigger(id: type.defaultID, ordinal: 1) else {
            preconditionFailure("Expected release default")
        }
        return rule
    }
}
