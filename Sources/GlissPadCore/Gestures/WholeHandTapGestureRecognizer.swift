import Foundation

final class WholeHandTapGestureRecognizer {
    let id: String
    let type: GestureTriggerType
    let rule: FiveAndMoreFingerGestureRule
    private var phase = WholeHandTapPhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, type: GestureTriggerType, rule: FiveAndMoreFingerGestureRule) {
        self.id = id
        self.type = type
        self.rule = rule
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            phase = .idle
            return nil
        }
        switch phase {
        case .idle:
            startTrackingIfPossible(frame)
        case .tracking(var state):
            return updateTracking(frame, state: &state)
        case .cancellingUntilRelease:
            if frame.activeTouches.isEmpty { phase = .idle }
        }
        return nil
    }

    private func startTrackingIfPossible(_ frame: TouchFrame) {
        let touches = frame.activeTouches
        guard contactCountAllowed(touches.count),
              let centroid = NormalizedPoint.centroid(of: touches),
              regionContains(centroid) else { return }
        phase = .tracking(WholeHandTapTrackingState(frame: frame, touches: touches, centroid: centroid))
    }

    private func updateTracking(_ frame: TouchFrame, state: inout WholeHandTapTrackingState) -> RecognizedGesture? {
        let touches = frame.activeTouches
        guard !touches.isEmpty else {
            let gesture = triggerOnReleaseIfNeeded(frame, state: state)
            phase = .idle
            return gesture
        }
        guard contactCountAllowed(touches.count),
              let centroid = NormalizedPoint.centroid(of: touches),
              state.startCentroid.distance(to: centroid) <= rule.wholeHandTap.maximumMovement else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.record(touches: touches)
        phase = .tracking(state)
        return nil
    }

    private func triggerOnReleaseIfNeeded(_ frame: TouchFrame, state: WholeHandTapTrackingState) -> RecognizedGesture? {
        guard durationAllowed(frame.timestamp - state.startedAt),
              areaSatisfied(state),
              palmSatisfied(state),
              canTrigger(at: frame.timestamp) else { return nil }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: type, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func contactCountAllowed(_ count: Int) -> Bool {
        guard count >= rule.wholeHandTap.minContactCount else { return false }
        guard let maxCount = rule.wholeHandTap.maxContactCount else { return true }
        return count <= maxCount
    }

    private func durationAllowed(_ duration: TimeInterval) -> Bool {
        let minDuration = TimeInterval(rule.wholeHandTap.minTapMilliseconds) / 1000
        let maxDuration = TimeInterval(rule.wholeHandTap.maxTapMilliseconds) / 1000
        return duration >= minDuration && duration <= maxDuration
    }

    private func areaSatisfied(_ state: WholeHandTapTrackingState) -> Bool {
        guard rule.wholeHandTap.requireLargeContactArea else { return true }
        return state.maxTotalArea >= rule.wholeHandTap.minTotalContactArea
            || state.maxAverageArea >= rule.wholeHandTap.minAverageContactArea
    }

    private func palmSatisfied(_ state: WholeHandTapTrackingState) -> Bool {
        guard rule.wholeHandTap.requirePalmLikeContact else { return true }
        switch rule.wholeHandTap.palmDetectionMode {
        case .disabledFallback:
            return true
        case .system, .heuristic:
            return state.maxContactCount >= rule.wholeHandTap.minContactCount && areaSatisfied(state)
        }
    }

    private func regionContains(_ point: NormalizedPoint) -> Bool {
        rule.wholeHandTap.region?.contains(point) ?? rule.common.region?.contains(point) ?? true
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }
}

private enum WholeHandTapPhase {
    case idle
    case tracking(WholeHandTapTrackingState)
    case cancellingUntilRelease
}

private struct WholeHandTapTrackingState {
    let startedAt: TimeInterval
    let startCentroid: NormalizedPoint
    private(set) var maxContactCount: Int
    private(set) var maxTotalArea: Double
    private(set) var maxAverageArea: Double

    init(frame: TouchFrame, touches: [TouchPoint], centroid: NormalizedPoint) {
        startedAt = frame.timestamp
        startCentroid = centroid
        maxContactCount = touches.count
        maxTotalArea = touches.totalContactArea
        maxAverageArea = touches.averageContactArea
    }

    mutating func record(touches: [TouchPoint]) {
        maxContactCount = max(maxContactCount, touches.count)
        maxTotalArea = max(maxTotalArea, touches.totalContactArea)
        maxAverageArea = max(maxAverageArea, touches.averageContactArea)
    }
}

private extension Array where Element == TouchPoint {
    var totalContactArea: Double {
        reduce(0) { $0 + $1.size }
    }

    var averageContactArea: Double {
        isEmpty ? 0 : totalContactArea / Double(count)
    }
}
