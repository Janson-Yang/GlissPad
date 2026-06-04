import Foundation

extension ThreeFingerGestureRecognizer {
    var effectiveTouchMovementTolerance: Double {
        rule.touch.movementTolerance
    }

    var longTouchReleaseResumeWindow: TimeInterval {
        0.30
    }

    func touchPressureCancels(_ frame: TouchFrame) -> Bool {
        frame.activeTouches.maximumPressure() >= TrackpadPressureThreshold.click
    }

    func qualifiedStableTouchFrame(
        _ collection: ThreeFingerCollectionState,
        releaseTimestamp: TimeInterval
    ) -> TouchFrame? {
        guard let startedAt = collection.threeFingerStartedAt,
              let frame = collection.threeFingerFrame,
              let touches = collection.threeFingerTouches else { return nil }
        let deadline = startedAt + stableFingerDuration
        guard releaseTimestamp + 0.000_5 >= deadline else { return nil }
        return TouchFrame(
            touches: touches,
            timestamp: deadline,
            frameNumber: frame.frameNumber,
            clickGeneration: frame.clickGeneration,
            hasRecentClick: frame.hasRecentClick
        )
    }

    func repeatTouchIfNeeded(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let interval = TimeInterval(rule.touch.repeatIntervalMilliseconds) / 1000
        let lastRepeatAt = state.lastRepeatAt ?? state.startedAt
        guard frame.timestamp - lastRepeatAt >= interval else {
            phase = .tracking(state)
            return nil
        }
        state.lastRepeatAt = frame.timestamp
        phase = .tracking(state)
        return recognizedGesture(frame)
    }
}
