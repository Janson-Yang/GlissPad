import Foundation

extension ThreeFingerGestureRecognizer {
    func processPress(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle, .collecting:
            startTrackingIfPossible(frame, region: rule.common.region)
        case .tracking(var state):
            return updatePressTracking(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    private func updatePressTracking(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard !active.isEmpty else { return finishPressOnRelease(frame, state: state) }
        guard active.count == 3 else {
            phase = .cancellingUntilRelease
            return nil
        }
        updateClickState(frame, state: &state)
        guard pressThresholdSatisfied(frame: frame, state: state, touches: active),
              pressureBiasSatisfied(active) else {
            phase = .tracking(state)
            return nil
        }
        state.completed = true
        if rule.press.triggerTiming == .pressDown, !state.triggered, canTrigger(at: frame.timestamp) {
            state.triggered = true
            phase = .tracking(state)
            return recognizedGesture(frame)
        }
        phase = .tracking(state)
        return nil
    }

    private func finishPressOnRelease(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> RecognizedGesture? {
        phase = .idle
        guard rule.press.triggerTiming == .pressUp,
              state.completed,
              !state.triggered,
              canTrigger(at: frame.timestamp) else {
            return nil
        }
        return recognizedGesture(frame)
    }

    private func pressThresholdSatisfied(
        frame: TouchFrame,
        state: ThreeFingerTrackingState,
        touches: [TouchPoint]
    ) -> Bool {
        let pressure = touches.maximumPressure()
        let threshold = rule.press.level == .force ? rule.press.forcePressure : rule.press.minimumPressure
        if pressure >= threshold { return true }
        guard rule.press.level == .normal else { return false }
        if state.sawClick || hasPressed(frame, baseline: state.clickBaseline) { return true }
        return rule.press.allowFallbackWithoutPressureData && pressure <= TrackpadPressureThreshold.touch
    }

    private func pressureBiasSatisfied(_ touches: [TouchPoint]) -> Bool {
        guard rule.press.pressureBias != .none else { return true }
        let sorted = touches.sortedByHorizontalPosition()
        guard sorted.count == 3 else { return false }
        let total = max(sorted.map(\.pressure).reduce(0, +), 0.000_001)
        let ratios = sorted.map { $0.pressure / total }
        switch rule.press.pressureBias {
        case .left:
            return ratio(ratios, index: 0, beats: [1, 2])
        case .middle:
            return ratio(ratios, index: 1, beats: [0, 2])
        case .right:
            return ratio(ratios, index: 2, beats: [0, 1])
        case .none:
            return true
        }
    }

    private func ratio(_ ratios: [Double], index: Int, beats others: [Int]) -> Bool {
        ratios[index] >= 0.45
            && others.allSatisfy { ratios[index] - ratios[$0] >= rule.press.pressureBiasThreshold }
    }
}
