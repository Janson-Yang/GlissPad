import Foundation

public func migrateFourFingerBTTTrigger(oldName: String) -> GestureRule? {
    switch normalizedFourFingerBTTName(oldName) {
    case "4 finger touch start":
        return fourFingerMigrationTrigger(.fourFingerTouch) { $0.touch.event = .touchStart }
    case "4 finger long touch":
        return fourFingerMigrationTrigger(.fourFingerTouch) { $0.touch.event = .longTouch }
    case "4 finger tap":
        return fourFingerMigrationTrigger(.fourFingerTap) { $0.tap.tapCount = 1 }
    case "4 finger double tap":
        return fourFingerMigrationTrigger(.fourFingerTap) { $0.tap.tapCount = 2 }
    case "4 finger click":
        return fourFingerMigrationTrigger(.fourFingerPress) { $0.press.level = .normal }
    case "4 finger force click":
        return fourFingerMigrationTrigger(.fourFingerPress) { $0.press.level = .force }
    case "4 finger swipe up":
        return fourFingerMigrationTrigger(.fourFingerSwipe) { $0.swipe.direction = .up }
    case "4 finger swipe down":
        return fourFingerMigrationTrigger(.fourFingerSwipe) { $0.swipe.direction = .down }
    case "4 finger swipe left":
        return fourFingerMigrationTrigger(.fourFingerSwipe) { $0.swipe.direction = .left }
    case "4 finger swipe right":
        return fourFingerMigrationTrigger(.fourFingerSwipe) { $0.swipe.direction = .right }
    case "pinch with thumb and 3 fingers":
        return fourFingerMigrationTrigger(.thumbThreeFingerScale) { $0.scale.direction = .pinchIn }
    case "spread with thumb and 3 fingers":
        return fourFingerMigrationTrigger(.thumbThreeFingerScale) { $0.scale.direction = .spreadOut }
    case "tiptap left (3 fingers fix)":
        return fourFingerMigrationTrigger(.fourFingerTipTap) { $0.tipTap.tapSide = .left }
    case "tiptap right (3 fingers fix)":
        return fourFingerMigrationTrigger(.fourFingerTipTap) { $0.tipTap.tapSide = .right }
    case "4 finger drawing":
        return fourFingerMigrationTrigger(.fourFingerDrawing) { _ in }
    default:
        return nil
    }
}

private func normalizedFourFingerBTTName(_ oldName: String) -> String {
    oldName
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
        .lowercased()
}

private func fourFingerMigrationTrigger(
    _ type: GestureTriggerType,
    configure: (inout FourFingerGestureRule) -> Void
) -> GestureRule? {
    let id = UUID().uuidString
    guard case .fourFinger(_, _, var rule) = type.defaultTrigger(id: id, ordinal: 1) else {
        return nil
    }
    configure(&rule)
    return .fourFinger(id: id, type: type, rule: rule)
}
