import Foundation

final class MultiFingerSwipeGestureRecognizer {
    private let id: String
    private let rule: MultiFingerSwipeGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = MultiFingerSwipePhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: MultiFingerSwipeGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            phase = .idle
            return nil
        }

        switch phase {
        case .idle:
            beginTrackingIfNeeded(frame.activeTouches)
        case .tracking(var state):
            return processTracking(&state, frame: frame)
        case .ending(let state):
            return processEnding(state, frame: frame)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        }
        return nil
    }

    private func beginTrackingIfNeeded(_ touches: [TouchPoint]) {
        guard touches.count == rule.fingerCount,
              region(rule.startRegion, contains: touches),
              let centroid = NormalizedPoint.centroid(of: touches) else {
            return
        }
        phase = .tracking(MultiFingerSwipeState(samples: [centroid], lastTouches: touches))
    }

    private func processTracking(
        _ state: inout MultiFingerSwipeState,
        frame: TouchFrame
    ) -> RecognizedGesture? {
        let activeTouches = frame.activeTouches
        guard !activeTouches.isEmpty else {
            return finish(state, frame: frame)
        }
        guard activeTouches.count <= rule.fingerCount else {
            phase = .cancellingUntilRelease
            return nil
        }
        guard activeTouches.count == rule.fingerCount,
              let centroid = NormalizedPoint.centroid(of: activeTouches) else {
            phase = .ending(state)
            return nil
        }
        state.append(centroid: centroid, touches: activeTouches)
        phase = .tracking(state)
        return nil
    }

    private func processEnding(
        _ state: MultiFingerSwipeState,
        frame: TouchFrame
    ) -> RecognizedGesture? {
        let activeTouches = frame.activeTouches
        guard !activeTouches.isEmpty else {
            return finish(state, frame: frame)
        }
        if activeTouches.count > rule.fingerCount {
            phase = .cancellingUntilRelease
        } else if activeTouches.count == rule.fingerCount {
            var resumed = state
            if let centroid = NormalizedPoint.centroid(of: activeTouches) {
                resumed.append(centroid: centroid, touches: activeTouches)
            }
            phase = .tracking(resumed)
        }
        return nil
    }

    private func finish(_ state: MultiFingerSwipeState, frame: TouchFrame) -> RecognizedGesture? {
        phase = .idle
        guard canTrigger(at: frame.timestamp),
              region(rule.endRegion, contains: state.lastTouches),
              pathLength(state.samples) >= rule.minimumTravel,
              RelativePathMatcher(template: rule.points, tolerance: rule.pointTolerance).matches(state.samples) else {
            return nil
        }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func region(_ region: NormalizedRegion?, contains touches: [TouchPoint]) -> Bool {
        guard let region else { return true }
        return touches.allSatisfy { region.contains($0.position) }
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }

    private func resetIfReleased(_ frame: TouchFrame) {
        guard frame.activeTouches.isEmpty else { return }
        phase = .idle
    }

    private func pathLength(_ points: [NormalizedPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        return zip(points, points.dropFirst()).map { $0.distance(to: $1) }.reduce(0, +)
    }
}

private struct MultiFingerSwipeState: Equatable {
    var samples: [NormalizedPoint]
    var lastTouches: [TouchPoint]

    mutating func append(centroid: NormalizedPoint, touches: [TouchPoint]) {
        if samples.last?.distance(to: centroid) ?? .infinity >= 0.004 {
            samples.append(centroid)
        }
        lastTouches = touches
    }
}

private enum MultiFingerSwipePhase: Equatable {
    case idle
    case tracking(MultiFingerSwipeState)
    case ending(MultiFingerSwipeState)
    case cancellingUntilRelease
}
