import Foundation

struct PressRecognitionState {
    var phase: PressPhase = .idle
    var anchor: NormalizedPoint?
    var lastTriggeredAt: TimeInterval?

    func canTrigger(at timestamp: TimeInterval, rule: PressGestureRule) -> Bool {
        guard let lastTriggeredAt else { return true }
        let cooldown = TimeInterval(rule.cooldownMilliseconds) / 1000
        return timestamp - lastTriggeredAt >= cooldown
    }

    mutating func recordTrigger(at timestamp: TimeInterval) {
        lastTriggeredAt = timestamp
    }

    func exceededMovementLimit(with touches: [TouchPoint], rule: PressGestureRule) -> Bool {
        guard let anchor, let centroid = NormalizedPoint.centroid(of: touches) else { return false }
        return centroid.distance(to: anchor) > rule.maximumMovement
    }
}

enum PressPhase: Equatable {
    case idle
    case possible(forceProgress: ForcePressProgress = ForcePressProgress(), clickBaseline: UInt64, sawClick: Bool)
    case armed(clickBaseline: UInt64, sawClick: Bool)
    case cancellingUntilRelease
}
