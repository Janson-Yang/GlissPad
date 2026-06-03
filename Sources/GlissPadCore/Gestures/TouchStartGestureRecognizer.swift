import Foundation

final class TouchStartGestureRecognizer {
    private let id: String
    private let rule: TouchStartGestureRule
    private let kind: RecognizedGesture.Kind
    private var previousActiveFingerCount = 0
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: TouchStartGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            previousActiveFingerCount = 0
            return nil
        }
        let activeTouches = frame.activeTouches
        defer { previousActiveFingerCount = activeTouches.count }
        guard previousActiveFingerCount < rule.fingerCount,
              activeTouches.count == rule.fingerCount,
              let centroid = NormalizedPoint.centroid(of: activeTouches),
              rule.region?.contains(centroid) ?? true,
              canTrigger(at: frame.timestamp) else {
            return nil
        }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }
}
