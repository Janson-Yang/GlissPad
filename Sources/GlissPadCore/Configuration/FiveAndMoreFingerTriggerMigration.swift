import Foundation

public func migrateFiveAndMoreFingerTrigger(oldName: String) -> GestureRule? {
    switch normalizedFiveAndMoreFingerName(oldName) {
    case "5 finger touch start":
        return fiveAndMoreMigrationTrigger(.fiveFingerTouch) { $0.touch.event = .touchStart }
    case "5 finger long touch":
        return fiveAndMoreMigrationTrigger(.fiveFingerTouch) { $0.touch.event = .longTouch }
    case "5 finger touch":
        return fiveAndMoreMigrationTrigger(.fiveFingerTouch) { $0.touch.event = .stableTouch }
    case "5 finger tap":
        return fiveAndMoreMigrationTrigger(.fiveFingerTap) { $0.tap.tapCount = 1 }
    case "5 finger click":
        return fiveAndMoreMigrationTrigger(.fiveFingerPress) { $0.press.level = .normal }
    case "5 finger force click":
        return fiveAndMoreMigrationTrigger(.fiveFingerPress) { $0.press.level = .force }
    case "pinch with thumb and 4 fingers":
        return fiveAndMoreMigrationTrigger(.thumbFourFingerScale) { $0.scale.direction = .pinchIn }
    case "spread with thumb and 4 fingers":
        return fiveAndMoreMigrationTrigger(.thumbFourFingerScale) { $0.scale.direction = .spreadOut }
    case "5 finger swipe up":
        return fiveAndMoreMigrationTrigger(.fiveFingerSwipe) { $0.swipe.direction = .up }
    case "5 finger swipe down":
        return fiveAndMoreMigrationTrigger(.fiveFingerSwipe) { $0.swipe.direction = .down }
    case "5 finger swipe left":
        return fiveAndMoreMigrationTrigger(.fiveFingerSwipe) { $0.swipe.direction = .left }
    case "5 finger swipe right":
        return fiveAndMoreMigrationTrigger(.fiveFingerSwipe) { $0.swipe.direction = .right }
    case "5 finger drawing":
        return fiveAndMoreMigrationTrigger(.fiveFingerDrawing) { _ in }
    case "11 finger tap / whole hand":
        return fiveAndMoreMigrationTrigger(.wholeHandTap) { $0.wholeHandTap.nominalContactCount = 11 }
    default:
        return nil
    }
}

public func migrateFiveAndMoreFingerBTTTrigger(oldName: String) -> GestureRule? {
    migrateFiveAndMoreFingerTrigger(oldName: oldName)
}

private func normalizedFiveAndMoreFingerName(_ oldName: String) -> String {
    oldName
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
        .lowercased()
}

private func fiveAndMoreMigrationTrigger(
    _ type: GestureTriggerType,
    configure: (inout FiveAndMoreFingerGestureRule) -> Void
) -> GestureRule? {
    let id = UUID().uuidString
    guard case .fiveAndMoreFinger(_, _, var rule) = type.defaultTrigger(id: id, ordinal: 1) else {
        return nil
    }
    configure(&rule)
    return .fiveAndMoreFinger(id: id, type: type, rule: rule)
}
