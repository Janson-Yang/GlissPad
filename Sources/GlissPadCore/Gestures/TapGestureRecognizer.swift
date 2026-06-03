import Foundation

final class TapGestureRecognizer {
    private let id: String
    private let rule: TapGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = TapPhase.idle
    private var pendingTap: PendingTap?
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: TapGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            reset()
            return nil
        }
        expirePendingTapIfNeeded(at: frame.timestamp)
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
        guard let centroid = activeCentroid(in: frame.activeTouches), clickStateAllowsStart(frame) else { return }
        guard rule.region?.contains(centroid) ?? true else { return }
        var forceProgress = ForcePressProgress()
        forceProgress.update(
            timestamp: frame.timestamp,
            pressure: maximumPressure(in: frame),
            activationThreshold: rule.minimumPressure,
            sustainingThreshold: rule.sustainingPressure,
            clickSatisfied: true
        )
        phase = .tracking(TapState(
            anchor: centroid,
            startedAt: frame.timestamp,
            clickBaseline: frame.clickGeneration,
            sawClick: frame.hasRecentClick,
            forceProgress: forceProgress
        ))
    }

    private func updateTracking(_ frame: TouchFrame, state: inout TapState) -> RecognizedGesture? {
        if frame.activeTouches.isEmpty {
            return finishOnRelease(frame, state: state)
        }
        guard let centroid = activeCentroid(in: frame.activeTouches),
              clickStateIsValid(frame, state: state),
              centroid.distance(to: state.anchor) <= rule.maximumMovement else {
            phase = .cancellingUntilRelease
            return nil
        }
        updateClickAndForce(frame, state: &state)
        phase = .tracking(state)
        return nil
    }

    private func finishOnRelease(_ frame: TouchFrame, state: TapState) -> RecognizedGesture? {
        phase = .idle
        guard isValidTap(frame, state: state), canTrigger(at: frame.timestamp) else { return nil }
        if rule.tapCount == 1 {
            return trigger(at: frame)
        }
        return processDoubleTap(frame, state: state)
    }

    private func processDoubleTap(_ frame: TouchFrame, state: TapState) -> RecognizedGesture? {
        let currentTap = PendingTap(timestamp: frame.timestamp, anchor: state.anchor)
        guard let pendingTap, frame.timestamp - pendingTap.timestamp <= doubleTapInterval else {
            self.pendingTap = currentTap
            return nil
        }
        guard pendingTap.anchor.distance(to: state.anchor) <= rule.maximumMovement else {
            self.pendingTap = currentTap
            return nil
        }
        self.pendingTap = nil
        return trigger(at: frame)
    }

    private func isValidTap(_ frame: TouchFrame, state: TapState) -> Bool {
        clickStateIsValid(frame, state: state)
            && frame.timestamp - state.startedAt <= TimeInterval(rule.maximumTapMilliseconds) / 1000
            && matchesPressRequirement(frame, state: state)
    }

    private func clickStateAllowsStart(_ frame: TouchFrame) -> Bool {
        rule.pressKind != .touch || ignoresSystemClickNoise || !frame.hasRecentClick
    }

    private func clickStateIsValid(_ frame: TouchFrame, state: TapState) -> Bool {
        rule.pressKind != .touch || ignoresSystemClickNoise
            || (frame.clickGeneration == state.clickBaseline && !frame.hasRecentClick)
    }

    private func updateClickAndForce(_ frame: TouchFrame, state: inout TapState) {
        state.sawClick = state.sawClick || frame.clickGeneration > state.clickBaseline || frame.hasRecentClick
        state.forceProgress.update(
            timestamp: frame.timestamp,
            pressure: maximumPressure(in: frame),
            activationThreshold: rule.minimumPressure,
            sustainingThreshold: rule.sustainingPressure,
            clickSatisfied: true
        )
    }

    private func matchesPressRequirement(_ frame: TouchFrame, state: TapState) -> Bool {
        switch rule.pressKind {
        case .touch:
            return true
        case .click, .forceClick:
            return state.sawClick
                && state.forceProgress.isSatisfied(
                    at: frame.timestamp,
                    minimumMilliseconds: rule.minimumForceMilliseconds
                )
        }
    }

    private func trigger(at frame: TouchFrame) -> RecognizedGesture {
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private var ignoresSystemClickNoise: Bool {
        rule.tapCount == 2
    }

    private var doubleTapInterval: TimeInterval {
        TimeInterval(rule.doubleTapMaximumIntervalMilliseconds) / 1000
    }

    private func expirePendingTapIfNeeded(at timestamp: TimeInterval) {
        guard let pendingTap, timestamp - pendingTap.timestamp > doubleTapInterval else { return }
        self.pendingTap = nil
    }

    private func activeCentroid(in touches: [TouchPoint]) -> NormalizedPoint? {
        guard touches.count == rule.fingerCount else { return nil }
        return NormalizedPoint.centroid(of: touches)
    }

    private func maximumPressure(in frame: TouchFrame) -> Double {
        frame.activeTouches.map(\.pressure).max() ?? 0
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }

    private func reset() {
        phase = .idle
        pendingTap = nil
    }
}

private struct PendingTap: Equatable {
    var timestamp: TimeInterval
    var anchor: NormalizedPoint
}

private struct TapState: Equatable {
    var anchor: NormalizedPoint
    var startedAt: TimeInterval
    var clickBaseline: UInt64
    var sawClick: Bool
    var forceProgress: ForcePressProgress
}

private enum TapPhase: Equatable {
    case idle
    case tracking(TapState)
    case cancellingUntilRelease
}
