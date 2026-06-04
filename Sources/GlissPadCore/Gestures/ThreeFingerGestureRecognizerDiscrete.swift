import Foundation

extension ThreeFingerGestureRecognizer {
    func processTouch(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle, .collecting:
            startTrackingIfPossible(frame, region: rule.common.region)
            guard case .tracking(var state) = phase else { return nil }
            return triggerTouchStartIfNeeded(frame, state: &state)
        case .tracking(var state):
            return updateTouchTracking(frame, state: &state)
        case .releasing(var state):
            return updateTouchRelease(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    func triggerTouchStartIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        guard rule.touch.event == .touchStart, canTrigger(at: frame.timestamp) else {
            phase = .tracking(state)
            return nil
        }
        state.triggered = true
        phase = .tracking(state)
        return recognizedGesture(frame)
    }

    private func updateTouchTracking(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        if active.count < 3 { return beginTouchRelease(frame, state: &state) }
        guard active.count == 3 else {
            phase = .cancellingUntilRelease
            return nil
        }
        updateClickState(frame, state: &state)
        if touchShouldCancel(frame, state: state, active: active) {
            phase = .cancellingUntilRelease
            return nil
        }
        state.appendSample(from: active)
        return triggerLongTouchIfNeeded(frame, state: &state)
    }

    private func beginTouchRelease(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        state.releaseStartedAt = frame.timestamp
        let gesture = triggerTouchReleaseIfNeeded(frame, state: &state)
        phase = frame.activeTouches.isEmpty ? .idle : .releasing(state)
        return gesture
    }

    private func updateTouchRelease(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        if frame.activeTouches.isEmpty {
            phase = .idle
        } else if canResumeLongTouch(frame, state: state) {
            var resumed = state
            resumed.releaseStartedAt = nil
            phase = .tracking(resumed)
        } else if frame.activeTouches.count >= 3 {
            phase = .cancellingUntilRelease
        } else {
            phase = .releasing(state)
        }
        return nil
    }

    private func triggerTouchReleaseIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        guard touchReleaseShouldTrigger(frame, state: state),
              !state.triggered,
              canTrigger(at: frame.timestamp) else { return nil }
        state.triggered = true
        return recognizedGesture(frame)
    }

    private func touchReleaseShouldTrigger(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> Bool {
        if rule.touch.event == .touchEnd { return true }
        guard rule.touch.event == .longTouch else { return false }
        return frame.timestamp - state.startedAt >= TimeInterval(rule.touch.holdMilliseconds) / 1000
    }

    private func touchShouldCancel(
        _ frame: TouchFrame,
        state: ThreeFingerTrackingState,
        active: [TouchPoint]
    ) -> Bool {
        let moved = touchMovedBeyondTolerance(active, state: state)
        let pressed = rule.touch.cancelOnPress && touchPressed(frame, state: state)
        return (rule.touch.cancelOnMovement && moved) || pressed
    }

    private func canResumeLongTouch(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> Bool {
        guard rule.touch.event == .longTouch,
              frame.activeTouches.count == 3,
              let releaseStartedAt = state.releaseStartedAt,
              frame.timestamp - releaseStartedAt <= longTouchReleaseResumeWindow,
              !touchMovedBeyondTolerance(frame.activeTouches, state: state) else { return false }
        return true
    }

    private func touchMovedBeyondTolerance(_ active: [TouchPoint], state: ThreeFingerTrackingState) -> Bool {
        if rule.touch.event == .longTouch,
           let anchor = state.centroidAnchor,
           let centroid = NormalizedPoint.centroid(of: active) {
            return centroid.distance(to: anchor) > effectiveTouchMovementTolerance
        }
        return movedBeyondAnchors(active, anchors: state.anchors, tolerance: effectiveTouchMovementTolerance)
    }

    private func touchPressed(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> Bool {
        if rule.touch.event == .longTouch {
            return longTouchPressureCancels(frame)
        }
        return state.sawClick || hasPressed(frame, baseline: state.clickBaseline)
    }

    func triggerLongTouchIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        guard rule.touch.event == .longTouch,
              rule.touch.triggerTiming != .release,
              frame.timestamp - state.startedAt >= TimeInterval(rule.touch.holdMilliseconds) / 1000 else {
            phase = .tracking(state)
            return nil
        }
        if state.triggered {
            return repeatLongTouchIfNeeded(frame, state: &state)
        }
        guard canTrigger(at: frame.timestamp) else {
            phase = .tracking(state)
            return nil
        }
        state.triggered = true
        state.lastRepeatAt = frame.timestamp
        phase = .tracking(state)
        return recognizedGesture(frame)
    }

    private func repeatLongTouchIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let interval = TimeInterval(rule.touch.repeatIntervalMilliseconds) / 1000
        let lastRepeatAt = state.lastRepeatAt ?? state.startedAt
        guard (rule.touch.repeatWhileHolding || rule.touch.triggerTiming == .continuous),
              frame.timestamp - lastRepeatAt >= interval else {
            phase = .tracking(state)
            return nil
        }
        state.lastRepeatAt = frame.timestamp
        phase = .tracking(state)
        return recognizedGesture(frame)
    }

    func processTap(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle, .collecting:
            startTrackingIfPossible(frame, region: rule.common.region)
        case .tracking(var state):
            return updateTapTracking(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    private func updateTapTracking(_ frame: TouchFrame, state: inout ThreeFingerTrackingState) -> RecognizedGesture? {
        let active = frame.activeTouches
        if active.isEmpty { return finishTapOnRelease(frame, state: state) }
        guard active.count == 3 else {
            phase = .cancellingUntilRelease
            return nil
        }
        updateClickState(frame, state: &state)
        guard !tapShouldCancel(state: state, active: active) else {
            phase = .cancellingUntilRelease
            return nil
        }
        phase = .tracking(state)
        return nil
    }

    private func finishTapOnRelease(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> RecognizedGesture? {
        phase = .idle
        guard frame.timestamp - state.startedAt <= TimeInterval(rule.tap.maximumTapMilliseconds) / 1000,
              !state.sawClick || !rule.tap.requireNoPress,
              canTrigger(at: frame.timestamp) else { return nil }
        return recordTap(frame, anchor: state.samples.last ?? NormalizedPoint(x: 0.5, y: 0.5))
    }

    private func tapShouldCancel(state: ThreeFingerTrackingState, active: [TouchPoint]) -> Bool {
        movedBeyondAnchors(active, anchors: state.anchors, tolerance: rule.tap.maximumMovement)
            || (state.sawClick && rule.tap.requireNoPress)
    }

    private func recordTap(_ frame: TouchFrame, anchor: NormalizedPoint) -> RecognizedGesture? {
        guard rule.tap.tapCount > 1 else { return recognizedGesture(frame) }
        let previous = pendingTap
        let nextCount = validPendingTap(previous, frame: frame, anchor: anchor) ? previous!.count + 1 : 1
        pendingTap = ThreeFingerPendingTap(count: nextCount, timestamp: frame.timestamp, anchor: anchor)
        guard nextCount >= rule.tap.tapCount else { return nil }
        pendingTap = nil
        return recognizedGesture(frame)
    }

    private func validPendingTap(_ pending: ThreeFingerPendingTap?, frame: TouchFrame, anchor: NormalizedPoint) -> Bool {
        guard let pending else { return false }
        let interval = TimeInterval(rule.tap.maximumInterTapIntervalMilliseconds) / 1000
        return frame.timestamp - pending.timestamp <= interval
            && pending.anchor.distance(to: anchor) <= rule.tap.maximumMovement
    }

    func expirePendingTapIfNeeded(at timestamp: TimeInterval) {
        guard let pendingTap else { return }
        let interval = TimeInterval(rule.tap.maximumInterTapIntervalMilliseconds) / 1000
        if timestamp - pendingTap.timestamp > interval { self.pendingTap = nil }
    }
}
