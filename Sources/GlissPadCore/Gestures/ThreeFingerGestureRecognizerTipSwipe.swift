import Foundation

extension ThreeFingerGestureRecognizer {
    func tipSwipeCompleted(
        frame: TouchFrame,
        state: ThreeFingerTipState,
        tip: TouchPoint
    ) -> Bool {
        let vector = displacement(from: state.activeAnchor, to: tip.position)
        let distance = hypot(vector.dx, vector.dy)
        let duration = max(frame.timestamp - state.startedAt, 0.001)
        return distance >= rule.tipSwipe.minimumTravel
            && distance / duration >= rule.tipSwipe.minimumVelocity
            && directionMatches(
                dx: vector.dx,
                dy: vector.dy,
                direction: rule.tipSwipe.direction,
                toleranceDegrees: rule.tipSwipe.directionToleranceDegrees
            )
    }

    func triggerTipSwipeIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTipState
    ) -> RecognizedGesture? {
        guard state.completed, !state.triggered, canTrigger(at: frame.timestamp) else {
            phase = .tip(state)
            return nil
        }
        switch rule.tipSwipe.triggerTiming {
        case .thresholdReached, .continuous:
            state.triggered = true
            phase = .tip(state)
            return recognizedGesture(frame)
        case .release:
            phase = .tip(state)
            return nil
        }
    }

    func finishTipSwipe(_ frame: TouchFrame, state: ThreeFingerTipState) -> RecognizedGesture? {
        phase = .tipBase(state.base)
        guard rule.tipSwipe.triggerTiming == .release,
              state.completed,
              !state.triggered,
              canTrigger(at: frame.timestamp) else {
            return nil
        }
        return recognizedGesture(frame)
    }
}

