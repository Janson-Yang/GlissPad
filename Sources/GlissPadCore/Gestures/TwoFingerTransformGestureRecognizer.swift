import Foundation

final class TwoFingerTransformGestureRecognizer {
    private let id: String
    private let rule: TwoFingerTransformGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = TransformPhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: TwoFingerTransformGestureRule, kind: RecognizedGesture.Kind) {
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
            guard let geometry = TwoFingerTransformGeometry(touches: frame.activeTouches),
                  rule.region?.contains(geometry.centroid) ?? true else { return nil }
            phase = .tracking(TwoFingerTransformTrackingState(start: geometry))
        case .tracking(var state):
            return updateTracking(frame, state: &state)
        case .ending(let state):
            return updateEnding(frame, state: state)
        case .cancellingUntilRelease:
            if frame.activeTouches.isEmpty { phase = .idle }
        }
        return nil
    }

    private func updateTracking(
        _ frame: TouchFrame,
        state: inout TwoFingerTransformTrackingState
    ) -> RecognizedGesture? {
        let activeTouches = frame.activeTouches
        guard !activeTouches.isEmpty else {
            return finish(state, frame: frame)
        }
        guard activeTouches.count <= 2 else {
            phase = .cancellingUntilRelease
            return nil
        }
        guard activeTouches.count == 2 else {
            phase = state.completed ? .ending(state) : .cancellingUntilRelease
            return nil
        }
        guard let current = TwoFingerTransformGeometry(touches: activeTouches),
              current.hasSameTouchIDs(as: state.start) else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.completed = state.completed || isCompleted(start: state.start, current: current)
        phase = .tracking(state)
        return nil
    }

    private func updateEnding(
        _ frame: TouchFrame,
        state: TwoFingerTransformTrackingState
    ) -> RecognizedGesture? {
        let activeTouches = frame.activeTouches
        guard !activeTouches.isEmpty else {
            return finish(state, frame: frame)
        }
        guard activeTouches.count <= 2 else {
            phase = .cancellingUntilRelease
            return nil
        }
        guard activeTouches.count == 2 else {
            phase = .ending(state)
            return nil
        }
        guard let current = TwoFingerTransformGeometry(touches: activeTouches),
              current.hasSameTouchIDs(as: state.start) else {
            phase = .cancellingUntilRelease
            return nil
        }
        var resumed = state
        resumed.completed = resumed.completed || isCompleted(start: state.start, current: current)
        phase = .tracking(resumed)
        return nil
    }

    private func finish(
        _ state: TwoFingerTransformTrackingState,
        frame: TouchFrame
    ) -> RecognizedGesture? {
        phase = .idle
        guard state.completed, canTrigger(at: frame.timestamp) else { return nil }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func isCompleted(
        start: TwoFingerTransformGeometry,
        current: TwoFingerTransformGeometry
    ) -> Bool {
        switch kind {
        case .pinchIn:
            return current.distance / start.distance <= 1 - rule.minimumScaleChange
        case .pinchOut:
            return current.distance / start.distance >= 1 + rule.minimumScaleChange
        case .rotateLeft:
            return start.matchesRotation(to: current, minimumDegrees: rule.minimumRotationDegrees, direction: .left)
        case .rotateRight:
            return start.matchesRotation(to: current, minimumDegrees: rule.minimumRotationDegrees, direction: .right)
        default:
            return false
        }
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }
}

private enum TransformPhase: Equatable {
    case idle
    case tracking(TwoFingerTransformTrackingState)
    case ending(TwoFingerTransformTrackingState)
    case cancellingUntilRelease
}
