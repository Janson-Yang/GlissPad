import Foundation

final class SwipeGestureRecognizer {
    private let id: String
    private let rule: SwipeGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = SwipePhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: SwipeGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            phase = .idle
            return nil
        }
        let activeTouches = frame.activeTouches

        switch phase {
        case .idle:
            guard let anchor = startingCentroid(from: activeTouches) else { return nil }
            phase = .tracking(anchor: anchor, completed: false)

        case .tracking(let anchor, let completed):
            guard !activeTouches.isEmpty else {
                phase = .idle
                guard completed, canTrigger(at: frame.timestamp) else { return nil }
                lastTriggeredAt = frame.timestamp
                return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
            }
            guard activeTouches.count == rule.fingerCount,
                  let centroid = NormalizedPoint.centroid(of: activeTouches) else {
                phase = .cancellingUntilRelease
                return nil
            }
            let movedRightEnough = centroid.x - anchor.x >= rule.minimumTravel
            phase = .tracking(anchor: anchor, completed: completed || movedRightEnough)

        case .cancellingUntilRelease:
            if activeTouches.isEmpty {
                phase = .idle
            }
        }

        return nil
    }

    private func startingCentroid(from touches: [TouchPoint]) -> NormalizedPoint? {
        guard touches.count == rule.fingerCount,
              let centroid = NormalizedPoint.centroid(of: touches),
              centroid.x <= rule.edgeWidth else {
            return nil
        }
        return centroid
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        let cooldown = TimeInterval(rule.cooldownMilliseconds) / 1000
        return timestamp - lastTriggeredAt >= cooldown
    }
}

private enum SwipePhase: Equatable {
    case idle
    case tracking(anchor: NormalizedPoint, completed: Bool)
    case cancellingUntilRelease
}
