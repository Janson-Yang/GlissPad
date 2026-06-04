import Foundation

extension ThreeFingerGestureRecognizer {
    func processTouchTimer(at timestamp: TimeInterval) -> RecognizedGesture? {
        switch phase {
        case .collecting(let collection):
            return startTouchTrackingFromTimer(collection, timestamp: timestamp)
        case .tracking(var state):
            return triggerTouchFromTimer(timestamp, state: &state)
        default:
            return nil
        }
    }

    func nextTouchDeadline() -> TimeInterval? {
        switch phase {
        case .collecting(let collection):
            return stableTouchDeadline(collection)
        case .tracking(let state):
            return longTouchDeadline(state)
        default:
            return nil
        }
    }

    private func startTouchTrackingFromTimer(
        _ collection: ThreeFingerCollectionState,
        timestamp: TimeInterval
    ) -> RecognizedGesture? {
        guard let deadline = stableTouchDeadline(collection),
              timerReached(timestamp, deadline: deadline),
              let frame = collection.threeFingerFrame,
              let touches = collection.threeFingerTouches else { return nil }
        let timerFrame = touchTimerFrame(from: frame, touches: touches, timestamp: deadline)
        var state = ThreeFingerTrackingState(frame: timerFrame, touches: touches)
        return triggerTouchStartIfNeeded(timerFrame, state: &state)
    }

    private func triggerTouchFromTimer(
        _ timestamp: TimeInterval,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        guard let deadline = longTouchDeadline(state), timerReached(timestamp, deadline: deadline) else { return nil }
        let frame = touchTimerFrame(
            touches: state.lastTouches,
            timestamp: max(timestamp, deadline),
            clickGeneration: state.clickBaseline
        )
        if rule.touch.event == .touchStart {
            return repeatTouchIfNeeded(frame, state: &state)
        }
        return triggerLongTouchIfNeeded(frame, state: &state)
    }

    private func stableTouchDeadline(_ collection: ThreeFingerCollectionState) -> TimeInterval? {
        collection.threeFingerStartedAt.map { $0 + stableFingerDuration }
    }

    private func longTouchDeadline(_ state: ThreeFingerTrackingState) -> TimeInterval? {
        if rule.touch.event == .touchStart {
            return touchStartContinuousDeadline(state)
        }
        guard rule.touch.event == .longTouch, rule.touch.triggerTiming != .release else { return nil }
        if !state.triggered {
            let holdDeadline = state.startedAt + TimeInterval(rule.touch.holdMilliseconds) / 1000
            guard let lastTriggeredAt else { return holdDeadline }
            return max(holdDeadline, lastTriggeredAt + TimeInterval(rule.cooldownMilliseconds) / 1000)
        }
        guard rule.touch.repeatWhileHolding || rule.touch.triggerTiming == .continuous else { return nil }
        let lastRepeatAt = state.lastRepeatAt ?? state.startedAt
        return lastRepeatAt + TimeInterval(rule.touch.repeatIntervalMilliseconds) / 1000
    }

    private func touchStartContinuousDeadline(_ state: ThreeFingerTrackingState) -> TimeInterval? {
        guard rule.touch.triggerTiming == .continuous, state.triggered else { return nil }
        let lastRepeatAt = state.lastRepeatAt ?? state.startedAt
        return lastRepeatAt + TimeInterval(rule.touch.repeatIntervalMilliseconds) / 1000
    }

    private func timerReached(_ timestamp: TimeInterval, deadline: TimeInterval) -> Bool {
        timestamp + 0.000_5 >= deadline
    }

    private func touchTimerFrame(
        from frame: TouchFrame,
        touches: [TouchPoint],
        timestamp: TimeInterval
    ) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: timestamp,
            frameNumber: frame.frameNumber,
            clickGeneration: frame.clickGeneration,
            hasRecentClick: frame.hasRecentClick
        )
    }

    private func touchTimerFrame(
        touches: [TouchPoint],
        timestamp: TimeInterval,
        clickGeneration: UInt64
    ) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: timestamp, frameNumber: -1, clickGeneration: clickGeneration)
    }
}
