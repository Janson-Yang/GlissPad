import Foundation

final class CircleGestureRecognizer {
    private let id: String
    private let rule: CircleGestureRule
    private let kind: RecognizedGesture.Kind
    private var samples: [NormalizedPoint] = []
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: CircleGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            samples.removeAll()
            return nil
        }
        let activeTouches = frame.activeTouches
        guard activeTouches.count == 1 else {
            return finishIfReleased(frame: frame, activeTouches: activeTouches)
        }
        samples.append(activeTouches[0].position)
        if samples.count > 96 {
            samples.removeFirst(samples.count - 96)
        }
        return nil
    }

    private func finishIfReleased(frame: TouchFrame, activeTouches: [TouchPoint]) -> RecognizedGesture? {
        defer { samples.removeAll() }
        guard activeTouches.isEmpty,
              canTrigger(at: frame.timestamp),
              CirclePathEvaluator(rule: rule).matches(samples) else { return nil }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        let cooldown = TimeInterval(rule.cooldownMilliseconds) / 1000
        return timestamp - lastTriggeredAt >= cooldown
    }
}

private struct CirclePathEvaluator {
    let rule: CircleGestureRule

    func matches(_ points: [NormalizedPoint]) -> Bool {
        guard points.count >= 8, let center = NormalizedPoint.centroid(points) else { return false }
        guard averageRadius(points, center: center) >= rule.minimumRadius else { return false }
        guard points[0].distance(to: points[points.count - 1]) <= rule.minimumRadius * 2.2 else { return false }
        let rotation = totalRotation(points, center: center)
        switch rule.direction {
        case .clockwise:
            return rotation <= -rule.minimumRotationRadians
        case .counterclockwise:
            return rotation >= rule.minimumRotationRadians
        }
    }

    private func averageRadius(_ points: [NormalizedPoint], center: NormalizedPoint) -> Double {
        points.reduce(0) { $0 + $1.distance(to: center) } / Double(points.count)
    }

    private func totalRotation(_ points: [NormalizedPoint], center: NormalizedPoint) -> Double {
        zip(points, points.dropFirst()).reduce(0) { total, pair in
            total + normalizedAngleDelta(from: angle(pair.0, center: center), to: angle(pair.1, center: center))
        }
    }

    private func angle(_ point: NormalizedPoint, center: NormalizedPoint) -> Double {
        atan2(point.y - center.y, point.x - center.x)
    }

    private func normalizedAngleDelta(from start: Double, to end: Double) -> Double {
        var delta = end - start
        while delta > Double.pi { delta -= Double.pi * 2 }
        while delta < -Double.pi { delta += Double.pi * 2 }
        return delta
    }
}

private extension NormalizedPoint {
    static func centroid(_ points: [NormalizedPoint]) -> NormalizedPoint? {
        guard !points.isEmpty else { return nil }
        let sum = points.reduce((x: 0.0, y: 0.0)) { total, point in
            (total.x + point.x, total.y + point.y)
        }
        return NormalizedPoint(x: sum.x / Double(points.count), y: sum.y / Double(points.count))
    }
}
