import Foundation

extension ThreeFingerGestureRecognizer {
    func processScale(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle, .collecting:
            startTrackingIfPossible(frame, region: rule.common.region)
        case .tracking(var state):
            return updateScaleTracking(frame, state: &state)
        case .releasing(var state):
            return updateScaleRelease(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    private func updateScaleTracking(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        if active.count < requiredFingerCount { return finishScaleDuringRelease(frame, state: &state) }
        guard active.count == requiredFingerCount else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.completed = state.completed || scaleCompleted(frame: frame, state: state, touches: active)
        state.appendSample(from: active)
        return triggerMovementIfNeeded(frame, state: &state, timing: rule.scale.triggerTiming)
    }

    private func updateScaleRelease(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard active.count != requiredFingerCount else {
            return updateScaleTracking(frame, state: &state)
        }
        return finishScaleDuringRelease(frame, state: &state)
    }

    private func finishScaleDuringRelease(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        completeScaleFromPartialRelease(frame, state: &state)
        let gesture = triggerScaleOnReleaseIfNeeded(frame, state: &state)
        phase = frame.activeTouches.isEmpty ? .idle : .releasing(state)
        return gesture
    }

    private func completeScaleFromPartialRelease(_ frame: TouchFrame, state: inout ThreeFingerTrackingState) {
        let touches = scaleReleaseCandidateTouches(frame, state: state)
        guard !touches.isEmpty else { return }
        state.completed = state.completed || scaleCompleted(frame: frame, state: state, touches: touches)
        state.appendSample(from: touches)
    }

    private func triggerScaleOnReleaseIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        guard rule.scale.triggerTiming == .release,
              state.completed,
              !state.triggered,
              canTrigger(at: frame.timestamp) else { return nil }
        state.triggered = true
        return recognizedGesture(frame)
    }

    private func scaleReleaseCandidateTouches(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> [TouchPoint] {
        frame.touches.filter { touch in
            state.anchors[touch.id] != nil && (touch.state.isTouchingSurface || touch.state == .breakTouch)
        }
    }

    private func scaleCompleted(frame: TouchFrame, state: ThreeFingerTrackingState, touches: [TouchPoint]) -> Bool {
        let initial = max(scaleDistance(in: state.startTouches), 0.001)
        let delta = scaleDistance(in: touches) / initial - 1
        let duration = max(frame.timestamp - state.startedAt, 0.001)
        guard abs(delta) / duration >= rule.scale.minimumScaleVelocity else { return false }
        switch rule.scale.direction {
        case .pinchIn:
            return delta <= -rule.scale.minimumScaleDelta
        case .spreadOut:
            return delta >= rule.scale.minimumScaleDelta
        case .any:
            return abs(delta) >= rule.scale.minimumScaleDelta
        }
    }

    private func scaleDistance(in touches: [TouchPoint]) -> Double {
        switch rule.scale.thumbDetectionMode {
        case .disabledFallback:
            return touches.averagePairwiseDistance()
        case .system, .heuristic:
            return heuristicThumbDistance(in: touches)
        }
    }

    private func heuristicThumbDistance(in touches: [TouchPoint]) -> Double {
        guard touches.count == requiredFingerCount,
              let thumb = touches.max(by: { $0.size < $1.size }) else {
            return touches.averagePairwiseDistance()
        }
        let fingers = touches.filter { $0.id != thumb.id }
        guard let fingerCenter = NormalizedPoint.centroid(of: fingers) else {
            return touches.averagePairwiseDistance()
        }
        return thumb.position.distance(to: fingerCenter)
    }
}
