import Foundation

final class CustomPathGestureRecognizer {
    private let id: String
    private let rule: CustomPathGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = CustomPathPhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: CustomPathGestureRule, kind: RecognizedGesture.Kind) {
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
            startTrackingIfPossible(frame)
        case .tracking(var state):
            return updateTracking(frame, state: &state)
        case .cancellingUntilRelease:
            if frame.activeTouches.isEmpty { phase = .idle }
        }
        return nil
    }

    private func startTrackingIfPossible(_ frame: TouchFrame) {
        guard let touch = singleTouch(in: frame.activeTouches) else { return }
        var state = CustomPathState(nextPointIndex: 0, samples: [])
        state.samples.append(touch.position)
        advanceIfMatched(touch.position, state: &state)
        phase = .tracking(state)
    }

    private func updateTracking(_ frame: TouchFrame, state: inout CustomPathState) -> RecognizedGesture? {
        if frame.activeTouches.isEmpty {
            return finishOnRelease(frame, state: state)
        }
        guard let touch = singleTouch(in: frame.activeTouches) else {
            phase = .cancellingUntilRelease
            return nil
        }
        appendSample(touch.position, state: &state)
        advanceIfMatched(touch.position, state: &state)
        phase = .tracking(state)
        return nil
    }

    private func finishOnRelease(_ frame: TouchFrame, state: CustomPathState) -> RecognizedGesture? {
        phase = .idle
        guard matched(state), canTrigger(at: frame.timestamp) else { return nil }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func matched(_ state: CustomPathState) -> Bool {
        switch kind {
        case .oneFingerDrawnPath:
            return FreeformPathMatcher(template: rule.points, tolerance: rule.pointTolerance)
                .matches(state.samples)
        default:
            return state.nextPointIndex >= rule.points.count
        }
    }

    private func advanceIfMatched(_ point: NormalizedPoint, state: inout CustomPathState) {
        guard kind == .oneFingerCustomPath else { return }
        while rule.points.indices.contains(state.nextPointIndex) {
            let target = rule.points[state.nextPointIndex]
            guard point.distance(to: target) <= rule.pointTolerance else { return }
            state.nextPointIndex += 1
        }
    }

    private func appendSample(_ point: NormalizedPoint, state: inout CustomPathState) {
        guard state.samples.last?.distance(to: point) != 0 else { return }
        state.samples.append(point)
    }

    private func singleTouch(in touches: [TouchPoint]) -> TouchPoint? {
        touches.count == 1 ? touches[0] : nil
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }
}

private struct CustomPathState: Equatable {
    var nextPointIndex: Int
    var samples: [NormalizedPoint]
}

private enum CustomPathPhase: Equatable {
    case idle
    case tracking(CustomPathState)
    case cancellingUntilRelease
}
