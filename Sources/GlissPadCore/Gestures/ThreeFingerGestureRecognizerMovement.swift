import Foundation

extension ThreeFingerGestureRecognizer {
    func processSwipe(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle:
            startTrackingIfPossible(frame, region: rule.common.startRegion ?? rule.common.region)
        case .tracking(var state):
            return updateSwipeTracking(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    private func updateSwipeTracking(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard !active.isEmpty else {
            return finishMovementOnRelease(frame, state: state, timing: rule.swipe.triggerTiming)
        }
        guard active.count == 3, let start = state.samples.first,
              let current = NormalizedPoint.centroid(of: active) else {
            phase = .cancellingUntilRelease
            return nil
        }
        updateClickState(frame, state: &state)
        state.appendSample(from: active)
        state.completed = state.completed || swipeCompleted(frame: frame, state: state, start: start, current: current)
        return triggerMovementIfNeeded(frame, state: &state, timing: rule.swipe.triggerTiming)
    }

    private func swipeCompleted(
        frame: TouchFrame,
        state: ThreeFingerTrackingState,
        start: NormalizedPoint,
        current: NormalizedPoint
    ) -> Bool {
        guard swipePressModeSatisfied(frame, state: state) else { return false }
        let vector = displacement(from: start, to: current)
        let distance = hypot(vector.dx, vector.dy)
        let duration = max(frame.timestamp - state.startedAt, 0.001)
        return distance >= rule.swipe.minimumTravel
            && distance / duration >= rule.swipe.minimumVelocity
            && directionMatches(
                dx: vector.dx,
                dy: vector.dy,
                direction: rule.swipe.direction,
                toleranceDegrees: rule.swipe.directionToleranceDegrees
            )
    }

    private func swipePressModeSatisfied(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> Bool {
        switch rule.swipe.pressMode {
        case .none:
            return true
        case .clickHeld:
            return state.sawClick || hasPressed(frame, baseline: state.clickBaseline)
        case .forceClickHeld:
            return frame.activeTouches.maximumPressure() >= rule.press.forcePressure
        }
    }

    func processScale(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle:
            startTrackingIfPossible(frame, region: rule.common.region)
        case .tracking(var state):
            return updateScaleTracking(frame, state: &state)
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
        guard !active.isEmpty else {
            return finishMovementOnRelease(frame, state: state, timing: rule.scale.triggerTiming)
        }
        guard active.count == 3 else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.completed = state.completed || scaleCompleted(frame: frame, state: state, touches: active)
        return triggerMovementIfNeeded(frame, state: &state, timing: rule.scale.triggerTiming)
    }

    private func scaleCompleted(frame: TouchFrame, state: ThreeFingerTrackingState, touches: [TouchPoint]) -> Bool {
        let initial = max(state.startTouches.averagePairwiseDistance(), 0.001)
        let delta = touches.averagePairwiseDistance() / initial - 1
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

    func processDrawing(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle:
            startTrackingIfPossible(frame, region: rule.common.startRegion ?? rule.common.region)
        case .tracking(var state):
            return updateDrawingTracking(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    private func updateDrawingTracking(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard !active.isEmpty else { return finishDrawing(frame, state: state) }
        guard active.count == 3 else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.appendSample(from: active)
        phase = .tracking(state)
        return nil
    }

    private func triggerMovementIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState,
        timing: ThreeFingerTriggerTiming
    ) -> RecognizedGesture? {
        guard state.completed, !state.triggered, canTrigger(at: frame.timestamp) else {
            phase = .tracking(state)
            return nil
        }
        switch timing {
        case .thresholdReached, .continuous:
            state.triggered = true
            phase = .tracking(state)
            return recognizedGesture(frame)
        case .release:
            phase = .tracking(state)
            return nil
        }
    }

    private func finishMovementOnRelease(
        _ frame: TouchFrame,
        state: ThreeFingerTrackingState,
        timing: ThreeFingerTriggerTiming
    ) -> RecognizedGesture? {
        phase = .idle
        guard timing == .release,
              state.completed,
              !state.triggered,
              canTrigger(at: frame.timestamp),
              regionContains(rule.common.endRegion, touches: state.lastTouches) else {
            return nil
        }
        return recognizedGesture(frame)
    }
}
