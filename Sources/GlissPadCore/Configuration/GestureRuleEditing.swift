import Foundation

public extension GestureRule {
    var name: String {
        ruleName
    }

    var actions: [GestureAction] {
        switch self {
        case .oneFinger(_, _, let rule): return rule.actions
        case .circle(_, _, let rule): return rule.actions
        case .shape(_, _, let rule): return rule.actions
        case .cornerClick(_, _, let rule): return rule.actions
        case .tap(_, _, let rule): return rule.actions
        case .oneFingerPress(_, _, let rule): return rule.actions
        case .customPath(_, _, let rule): return rule.actions
        case .touchStart(_, _, let rule): return rule.actions
        case .tipTap(_, _, let rule): return rule.actions
        case .transform(_, _, let rule): return rule.actions
        case .multiFingerSwipe(_, _, let rule): return rule.actions
        case .press(_, _, let rule): return rule.actions
        case .swipe(_, _, let rule): return rule.actions
        case .hold(_, _, let rule): return rule.actions
        case .release(_, _, let rule): return rule.actions
        case .threeFinger(_, _, let rule): return rule.actions
        case .fourFinger(_, _, let rule): return rule.actions
        case .fiveAndMoreFinger(_, _, let rule): return rule.actions
        }
    }

    func replacingActions(_ actions: [GestureAction]) -> GestureRule {
        switch self {
        case .oneFinger(let id, let type, var rule):
            rule.actions = actions
            return .oneFinger(id: id, type: type, rule: rule)
        case .circle(let id, let type, var rule):
            rule.actions = actions
            return .circle(id: id, type: type, rule: rule)
        case .shape(let id, let type, var rule):
            rule.actions = actions
            return .shape(id: id, type: type, rule: rule)
        case .cornerClick(let id, let type, var rule):
            rule.actions = actions
            return .cornerClick(id: id, type: type, rule: rule)
        case .tap(let id, let type, var rule):
            rule.actions = actions
            return .tap(id: id, type: type, rule: rule)
        case .oneFingerPress(let id, let type, var rule):
            rule.actions = actions
            return .oneFingerPress(id: id, type: type, rule: rule)
        case .customPath(let id, let type, var rule):
            rule.actions = actions
            return .customPath(id: id, type: type, rule: rule)
        case .touchStart(let id, let type, var rule):
            rule.actions = actions
            return .touchStart(id: id, type: type, rule: rule)
        case .tipTap(let id, let type, var rule):
            rule.actions = actions
            return .tipTap(id: id, type: type, rule: rule)
        case .transform(let id, let type, var rule):
            rule.actions = actions
            return .transform(id: id, type: type, rule: rule)
        case .multiFingerSwipe(let id, let type, var rule):
            rule.actions = actions
            return .multiFingerSwipe(id: id, type: type, rule: rule)
        case .press(let id, let type, var rule):
            rule.actions = actions
            return .press(id: id, type: type, rule: rule)
        case .swipe(let id, let type, var rule):
            rule.actions = actions
            return .swipe(id: id, type: type, rule: rule)
        case .hold(let id, let type, var rule):
            rule.actions = actions
            return .hold(id: id, type: type, rule: rule)
        case .release(let id, let type, var rule):
            rule.actions = actions
            return .release(id: id, type: type, rule: rule)
        case .threeFinger(let id, let type, var rule):
            rule.actions = actions
            return .threeFinger(id: id, type: type, rule: rule)
        case .fourFinger(let id, let type, var rule):
            rule.actions = actions
            return .fourFinger(id: id, type: type, rule: rule)
        case .fiveAndMoreFinger(let id, let type, var rule):
            rule.actions = actions
            return .fiveAndMoreFinger(id: id, type: type, rule: rule)
        }
    }

    func replacingName(_ name: String) -> GestureRule {
        switch self {
        case .oneFinger(let id, let type, var rule):
            rule.name = name
            return .oneFinger(id: id, type: type, rule: rule)
        case .circle(let id, let type, var rule):
            rule.name = name
            return .circle(id: id, type: type, rule: rule)
        case .shape(let id, let type, var rule):
            rule.name = name
            return .shape(id: id, type: type, rule: rule)
        case .cornerClick(let id, let type, var rule):
            rule.name = name
            return .cornerClick(id: id, type: type, rule: rule)
        case .tap(let id, let type, var rule):
            rule.name = name
            return .tap(id: id, type: type, rule: rule)
        case .oneFingerPress(let id, let type, var rule):
            rule.name = name
            return .oneFingerPress(id: id, type: type, rule: rule)
        case .customPath(let id, let type, var rule):
            rule.name = name
            return .customPath(id: id, type: type, rule: rule)
        case .touchStart(let id, let type, var rule):
            rule.name = name
            return .touchStart(id: id, type: type, rule: rule)
        case .tipTap(let id, let type, var rule):
            rule.name = name
            return .tipTap(id: id, type: type, rule: rule)
        case .transform(let id, let type, var rule):
            rule.name = name
            return .transform(id: id, type: type, rule: rule)
        case .multiFingerSwipe(let id, let type, var rule):
            rule.name = name
            return .multiFingerSwipe(id: id, type: type, rule: rule)
        case .press(let id, let type, var rule):
            rule.name = name
            return .press(id: id, type: type, rule: rule)
        case .swipe(let id, let type, var rule):
            rule.name = name
            return .swipe(id: id, type: type, rule: rule)
        case .hold(let id, let type, var rule):
            rule.name = name
            return .hold(id: id, type: type, rule: rule)
        case .release(let id, let type, var rule):
            rule.name = name
            return .release(id: id, type: type, rule: rule)
        case .threeFinger(let id, let type, var rule):
            rule.name = name
            return .threeFinger(id: id, type: type, rule: rule)
        case .fourFinger(let id, let type, var rule):
            rule.name = name
            return .fourFinger(id: id, type: type, rule: rule)
        case .fiveAndMoreFinger(let id, let type, var rule):
            rule.name = name
            return .fiveAndMoreFinger(id: id, type: type, rule: rule)
        }
    }

    func replacingIdentifier(_ id: String) -> GestureRule {
        switch self {
        case .oneFinger(_, let type, let rule):
            return .oneFinger(id: id, type: type, rule: rule)
        case .circle(_, let type, let rule):
            return .circle(id: id, type: type, rule: rule)
        case .shape(_, let type, let rule):
            return .shape(id: id, type: type, rule: rule)
        case .cornerClick(_, let type, let rule):
            return .cornerClick(id: id, type: type, rule: rule)
        case .tap(_, let type, let rule):
            return .tap(id: id, type: type, rule: rule)
        case .oneFingerPress(_, let type, let rule):
            return .oneFingerPress(id: id, type: type, rule: rule)
        case .customPath(_, let type, let rule):
            return .customPath(id: id, type: type, rule: rule)
        case .touchStart(_, let type, let rule):
            return .touchStart(id: id, type: type, rule: rule)
        case .tipTap(_, let type, let rule):
            return .tipTap(id: id, type: type, rule: rule)
        case .transform(_, let type, let rule):
            return .transform(id: id, type: type, rule: rule)
        case .multiFingerSwipe(_, let type, let rule):
            return .multiFingerSwipe(id: id, type: type, rule: rule)
        case .press(_, let type, let rule):
            return .press(id: id, type: type, rule: rule)
        case .swipe(_, let type, let rule):
            return .swipe(id: id, type: type, rule: rule)
        case .hold(_, let type, let rule):
            return .hold(id: id, type: type, rule: rule)
        case .release(_, let type, let rule):
            return .release(id: id, type: type, rule: rule)
        case .threeFinger(_, let type, let rule):
            return .threeFinger(id: id, type: type, rule: rule)
        case .fourFinger(_, let type, let rule):
            return .fourFinger(id: id, type: type, rule: rule)
        case .fiveAndMoreFinger(_, let type, let rule):
            return .fiveAndMoreFinger(id: id, type: type, rule: rule)
        }
    }
}

private extension GestureRule {
    var ruleName: String {
        switch self {
        case .oneFinger(_, _, let rule): return rule.name
        case .circle(_, _, let rule): return rule.name
        case .shape(_, _, let rule): return rule.name
        case .cornerClick(_, _, let rule): return rule.name
        case .tap(_, _, let rule): return rule.name
        case .oneFingerPress(_, _, let rule): return rule.name
        case .customPath(_, _, let rule): return rule.name
        case .touchStart(_, _, let rule): return rule.name
        case .tipTap(_, _, let rule): return rule.name
        case .transform(_, _, let rule): return rule.name
        case .multiFingerSwipe(_, _, let rule): return rule.name
        case .press(_, _, let rule): return rule.name
        case .swipe(_, _, let rule): return rule.name
        case .hold(_, _, let rule): return rule.name
        case .release(_, _, let rule): return rule.name
        case .threeFinger(_, _, let rule): return rule.name
        case .fourFinger(_, _, let rule): return rule.name
        case .fiveAndMoreFinger(_, _, let rule): return rule.name
        }
    }
}
