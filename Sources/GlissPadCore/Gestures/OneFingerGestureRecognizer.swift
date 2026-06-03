import Foundation

final class OneFingerGestureRecognizer {
    private let id: String
    private let rule: OneFingerGestureRule
    private let kind: RecognizedGesture.Kind
    private var previousActiveFingerCount = 0
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: OneFingerGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            previousActiveFingerCount = 0
            return nil
        }
        let activeFingerCount = frame.activeTouches.count
        defer { previousActiveFingerCount = activeFingerCount }
        guard previousActiveFingerCount == 0, activeFingerCount == 1 else { return nil }
        guard isInsideRegion(frame.activeTouches[0]) else { return nil }
        guard canTrigger(at: frame.timestamp) else { return nil }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func isInsideRegion(_ touch: TouchPoint) -> Bool {
        rule.region?.contains(touch.position) ?? true
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        let cooldown = TimeInterval(rule.cooldownMilliseconds) / 1000
        return timestamp - lastTriggeredAt >= cooldown
    }
}
