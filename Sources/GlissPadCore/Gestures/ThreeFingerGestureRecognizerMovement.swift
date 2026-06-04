import Foundation

extension ThreeFingerGestureRecognizer {
    func processSwipe(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle, .collecting:
            startTrackingIfPossible(frame, region: rule.common.startRegion ?? rule.common.region)
        case .tracking(var state):
            return updateSwipeTracking(frame, state: &state)
        case .releasing(var state):
            return updateSwipeRelease(frame, state: &state)
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
        if active.count < 3 { return finishSwipeDuringRelease(frame, state: &state) }
        guard active.count == 3, let start = state.samples.first,
              let current = NormalizedPoint.centroid(of: active) else {
            phase = .cancellingUntilRelease
            return nil
        }
        updateClickState(frame, state: &state)
        state.appendSample(from: active)
        state.completed = state.completed || swipeCompleted(
            frame: frame,
            state: state,
            touches: active,
            start: start,
            current: current
        )
        return triggerMovementIfNeeded(frame, state: &state, timing: rule.swipe.triggerTiming)
    }

    private func updateSwipeRelease(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard active.count != 3 else {
            return updateSwipeTracking(frame, state: &state)
        }
        return finishSwipeDuringRelease(frame, state: &state)
    }

    private func swipeCompleted(
        frame: TouchFrame,
        state: ThreeFingerTrackingState,
        touches: [TouchPoint],
        start: NormalizedPoint,
        current: NormalizedPoint
    ) -> Bool {
        guard swipePressModeSatisfied(frame, state: state) else { return false }
        let vector = displacement(from: start, to: current)
        let distance = hypot(vector.dx, vector.dy)
        let duration = max(frame.timestamp - state.startedAt, 0.001)
        return distance >= rule.swipe.minimumTravel
            && distance / duration >= effectiveSwipeMinimumVelocity
            && regionContains(rule.common.endRegion, touches: touches)
            && directionMatches(
                dx: vector.dx,
                dy: vector.dy,
                direction: rule.swipe.direction,
                toleranceDegrees: rule.swipe.directionToleranceDegrees
            )
    }

    private func finishSwipeDuringRelease(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        completeSwipeFromPartialRelease(frame, state: &state)
        let gesture = triggerSwipeOnReleaseIfNeeded(frame, state: &state)
        phase = frame.activeTouches.isEmpty ? .idle : .releasing(state)
        return gesture
    }

    private func completeSwipeFromPartialRelease(_ frame: TouchFrame, state: inout ThreeFingerTrackingState) {
        let touches = releaseCandidateTouches(frame, state: state)
        guard !touches.isEmpty,
              let start = state.samples.first,
              let current = NormalizedPoint.centroid(of: touches) else { return }
        state.appendSample(from: touches)
        state.completed = state.completed || swipeCompleted(
            frame: frame,
            state: state,
            touches: touches,
            start: start,
            current: current
        )
    }

    private func releaseCandidateTouches(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> [TouchPoint] {
        frame.touches.filter { touch in
            state.anchors[touch.id] != nil && (touch.state.isTouchingSurface || touch.state == .breakTouch)
        }
    }

    private func triggerSwipeOnReleaseIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        guard rule.swipe.triggerTiming != .continuous,
              state.completed,
              !state.triggered,
              canTrigger(at: frame.timestamp) else { return nil }
        state.triggered = true
        return recognizedGesture(frame)
    }

    private func swipePressModeSatisfied(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> Bool {
        switch rule.swipe.pressMode {
        case .none:
            return true
        case .clickHeld:
            return state.sawClick
                || hasPressed(frame, baseline: state.clickBaseline)
                || state.maximumObservedPressure >= sustainedClickPressureThreshold
        case .forceClickHeld:
            return state.maximumObservedPressure >= sustainedForcePressureThreshold
        }
    }

    private var sustainedClickPressureThreshold: Double {
        min(rule.press.minimumPressure, TrackpadPressureThreshold.clickSustain)
    }

    private var sustainedForcePressureThreshold: Double {
        min(rule.press.forcePressure, TrackpadPressureThreshold.forceClickSustain)
    }

    private var effectiveSwipeMinimumVelocity: Double {
        switch rule.swipe.pressMode {
        case .none:
            return rule.swipe.minimumVelocity
        case .clickHeld, .forceClickHeld:
            return min(rule.swipe.minimumVelocity, 0.35)
        }
    }

    func triggerMovementIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState,
        timing: ThreeFingerTriggerTiming
    ) -> RecognizedGesture? {
        guard state.completed else {
            phase = .tracking(state)
            return nil
        }
        switch timing {
        case .thresholdReached:
            guard !state.triggered, canTrigger(at: frame.timestamp) else {
                phase = .tracking(state)
                return nil
            }
            state.triggered = true
            phase = .tracking(state)
            return recognizedGesture(frame)
        case .continuous:
            guard canTrigger(at: frame.timestamp) else {
                phase = .tracking(state)
                return nil
            }
            state.triggered = true
            phase = .tracking(state)
            return recognizedGesture(frame)
        case .release:
            phase = .tracking(state)
            return nil
        }
    }

    func finishMovementOnRelease(
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
