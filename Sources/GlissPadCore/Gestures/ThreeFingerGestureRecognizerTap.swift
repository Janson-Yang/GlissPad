import Foundation

extension ThreeFingerGestureRecognizer {
    func processTap(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle:
            startTrackingIfPossible(frame, region: rule.common.region)
        case .collecting(let collection):
            if let gesture = finishCollectedTapIfNeeded(frame, collection: collection) {
                return gesture
            }
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

    private func finishCollectedTapIfNeeded(
        _ frame: TouchFrame,
        collection: ThreeFingerCollectionState
    ) -> RecognizedGesture? {
        guard frame.activeTouches.count < requiredFingerCount,
              let stableFrame = qualifiedStableTouchFrame(collection, releaseTimestamp: frame.timestamp),
              let touches = collection.threeFingerTouches else { return nil }
        let state = ThreeFingerTrackingState(frame: stableFrame, touches: touches)
        return finishTapOnRelease(frame, state: state)
    }

    private func updateTapTracking(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        if active.count < requiredFingerCount { return finishTapOnRelease(frame, state: state) }
        guard active.count == requiredFingerCount, !tapShouldCancel(frame: frame, state: state, active: active) else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.appendSample(from: active)
        phase = .tracking(state)
        return nil
    }

    private func finishTapOnRelease(
        _ frame: TouchFrame,
        state: ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        phase = .idle
        guard frame.timestamp - state.startedAt <= TimeInterval(rule.tap.maximumTapMilliseconds) / 1000,
              canTrigger(at: frame.timestamp) else { return nil }
        return recordTap(frame, anchor: state.samples.last ?? state.centroidAnchor ?? NormalizedPoint(x: 0.5, y: 0.5))
    }

    private func tapShouldCancel(
        frame: TouchFrame,
        state: ThreeFingerTrackingState,
        active: [TouchPoint]
    ) -> Bool {
        let moved = tapMovedBeyondTolerance(active, state: state)
        let pressed = rule.tap.requireNoPress && touchPressureCancels(frame)
        return moved || pressed
    }

    private func tapMovedBeyondTolerance(
        _ active: [TouchPoint],
        state: ThreeFingerTrackingState
    ) -> Bool {
        guard let anchor = state.centroidAnchor,
              let centroid = NormalizedPoint.centroid(of: active) else { return true }
        return centroid.distance(to: anchor) > rule.tap.maximumMovement
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
