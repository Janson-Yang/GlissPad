import Foundation
import GlissPadCore

struct GestureSlot: Hashable {
    var index: Int

    init(index: Int) {
        self.index = index
    }

    init?(rawValue: Int) {
        guard rawValue >= 0 else { return nil }
        index = rawValue
    }

    var rawValue: Int {
        index
    }

    func trigger(in configuration: AppConfiguration) -> GestureRule? {
        guard configuration.gestures.triggers.indices.contains(index) else { return nil }
        return configuration.gestures.triggers[index]
    }

    func title(in configuration: AppConfiguration) -> String {
        trigger(in: configuration)?.type.displayName ?? "Trigger"
    }

    func displayName(in configuration: AppConfiguration) -> String {
        trigger(in: configuration)?.name ?? "Trigger"
    }

    func symbolName(in configuration: AppConfiguration) -> String {
        trigger(in: configuration)?.type.symbolName ?? "hand.tap.fill"
    }

    func pressRule(in configuration: AppConfiguration) -> PressGestureRule? {
        guard case .press(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func oneFingerRule(in configuration: AppConfiguration) -> OneFingerGestureRule? {
        guard case .oneFinger(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func circleRule(in configuration: AppConfiguration) -> CircleGestureRule? {
        guard case .circle(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func shapeRule(in configuration: AppConfiguration) -> ShapeGestureRule? {
        guard case .shape(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func cornerClickRule(in configuration: AppConfiguration) -> CornerClickGestureRule? {
        guard case .cornerClick(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func tapRule(in configuration: AppConfiguration) -> TapGestureRule? {
        guard case .tap(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func oneFingerPressRule(in configuration: AppConfiguration) -> OneFingerPressGestureRule? {
        guard case .oneFingerPress(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func customPathRule(in configuration: AppConfiguration) -> CustomPathGestureRule? {
        guard case .customPath(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func touchStartRule(in configuration: AppConfiguration) -> TouchStartGestureRule? {
        guard case .touchStart(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func tipTapRule(in configuration: AppConfiguration) -> TipTapGestureRule? {
        guard case .tipTap(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func transformRule(in configuration: AppConfiguration) -> TwoFingerTransformGestureRule? {
        guard case .transform(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func multiFingerSwipeRule(in configuration: AppConfiguration) -> MultiFingerSwipeGestureRule? {
        guard case .multiFingerSwipe(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func swipeRule(in configuration: AppConfiguration) -> SwipeGestureRule? {
        guard case .swipe(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func holdRule(in configuration: AppConfiguration) -> HoldGestureRule? {
        guard case .hold(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func releaseRule(in configuration: AppConfiguration) -> ReleaseGestureRule? {
        guard case .release(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func actions(in configuration: AppConfiguration) -> [GestureAction] {
        trigger(in: configuration)?.actions ?? []
    }

    func actionTestKey(forActionIndex actionIndex: Int, in configuration: AppConfiguration) -> ActionTestKey? {
        guard let trigger = trigger(in: configuration) else { return nil }
        return ActionTestKey(triggerID: trigger.id, actionIndex: actionIndex)
    }

    func isEnabled(in configuration: AppConfiguration) -> Bool {
        switch trigger(in: configuration) {
        case .oneFinger(_, _, let rule): return rule.isEnabled
        case .circle(_, _, let rule): return rule.isEnabled
        case .shape(_, _, let rule): return rule.isEnabled
        case .cornerClick(_, _, let rule): return rule.isEnabled
        case .tap(_, _, let rule): return rule.isEnabled
        case .oneFingerPress(_, _, let rule): return rule.isEnabled
        case .customPath(_, _, let rule): return rule.isEnabled
        case .touchStart(_, _, let rule): return rule.isEnabled
        case .tipTap(_, _, let rule): return rule.isEnabled
        case .transform(_, _, let rule): return rule.isEnabled
        case .multiFingerSwipe(_, _, let rule): return rule.isEnabled
        case .press(_, _, let rule): return rule.isEnabled
        case .swipe(_, _, let rule): return rule.isEnabled
        case .hold(_, _, let rule): return rule.isEnabled
        case .release(_, _, let rule): return rule.isEnabled
        case nil: return false
        }
    }

    func write(_ rule: PressGestureRule, to configuration: inout AppConfiguration) {
        guard case .press(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .press(id: id, type: type, rule: rule)
    }

    func write(_ rule: OneFingerGestureRule, to configuration: inout AppConfiguration) {
        guard case .oneFinger(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .oneFinger(id: id, type: type, rule: rule)
    }

    func write(_ rule: CircleGestureRule, to configuration: inout AppConfiguration) {
        guard case .circle(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .circle(id: id, type: type, rule: rule)
    }

    func write(_ rule: ShapeGestureRule, to configuration: inout AppConfiguration) {
        guard case .shape(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .shape(id: id, type: type, rule: rule)
    }

    func write(_ rule: CornerClickGestureRule, to configuration: inout AppConfiguration) {
        guard case .cornerClick(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .cornerClick(id: id, type: type, rule: rule)
    }

    func write(_ rule: TapGestureRule, to configuration: inout AppConfiguration) {
        guard case .tap(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .tap(id: id, type: type, rule: rule)
    }

    func write(_ rule: OneFingerPressGestureRule, to configuration: inout AppConfiguration) {
        guard case .oneFingerPress(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .oneFingerPress(id: id, type: type, rule: rule)
    }

    func write(_ rule: CustomPathGestureRule, to configuration: inout AppConfiguration) {
        guard case .customPath(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .customPath(id: id, type: type, rule: rule)
    }

    func write(_ rule: TouchStartGestureRule, to configuration: inout AppConfiguration) {
        guard case .touchStart(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .touchStart(id: id, type: type, rule: rule)
    }

    func write(_ rule: TipTapGestureRule, to configuration: inout AppConfiguration) {
        guard case .tipTap(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .tipTap(id: id, type: type, rule: rule)
    }

    func write(_ rule: TwoFingerTransformGestureRule, to configuration: inout AppConfiguration) {
        guard case .transform(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .transform(id: id, type: type, rule: rule)
    }

    func write(_ rule: MultiFingerSwipeGestureRule, to configuration: inout AppConfiguration) {
        guard case .multiFingerSwipe(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .multiFingerSwipe(id: id, type: type, rule: rule)
    }

    func write(_ rule: SwipeGestureRule, to configuration: inout AppConfiguration) {
        guard case .swipe(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .swipe(id: id, type: type, rule: rule)
    }

    func write(_ rule: HoldGestureRule, to configuration: inout AppConfiguration) {
        guard case .hold(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .hold(id: id, type: type, rule: rule)
    }

    func write(_ rule: ReleaseGestureRule, to configuration: inout AppConfiguration) {
        guard case .release(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .release(id: id, type: type, rule: rule)
    }

    func writeActions(_ actions: [GestureAction], to configuration: inout AppConfiguration) {
        guard let trigger = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = trigger.replacingActions(actions)
    }
}

extension GestureTriggerType {
    var symbolName: String {
        switch self {
        case .oneFingerTouchStart: return "hand.point.up.left.fill"
        case .oneFingerLongPress: return "hand.tap.fill"
        case .oneFingerCircle: return "arrow.clockwise.circle.fill"
        case .oneFingerSquare: return "square"
        case .oneFingerTriangle: return "triangle"
        case .oneFingerCornerClick: return "scope"
        case .oneFingerTap: return "hand.tap.fill"
        case .oneFingerDoubleTap: return "hand.tap.fill"
        case .oneFingerPress: return "hand.tap.fill"
        case .oneFingerCustomPath: return "scribble.variable"
        case .oneFingerDrawnPath: return "scribble.variable"
        case .twoFingerTouchStart: return "hand.point.up.left.fill"
        case .twoFingerTap: return "hand.tap.fill"
        case .tipTap: return "hand.tap.fill"
        case .pinchIn: return "arrow.down.right.and.arrow.up.left"
        case .pinchOut: return "arrow.up.left.and.arrow.down.right"
        case .rotateLeft: return "rotate.left.fill"
        case .rotateRight: return "rotate.right.fill"
        case .freeformTwoFingerSwipe: return "point.topleft.down.curvedto.point.bottomright.up"
        case .regionTwoFingerSwipe: return "arrow.right.square.fill"
        case .threeFingerForcePress: return "hand.tap.fill"
        case .upperLeftForcePress: return "command"
        case .leftEdgeTwoFingerSwipe: return "arrow.right"
        case .twoFingerHold: return "timer"
        case .upperRightForcePress: return "keyboard.fill"
        case .releaseLastFinger: return "hand.raised.fill"
        }
    }
}
