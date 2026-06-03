import Foundation

final class HoldGestureRecognizer {
    private let id: String
    private let rule: HoldGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = HoldPhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: HoldGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            phase = .idle
            return nil
        }
        let activeTouches = frame.activeTouches

        switch phase {
        case .idle:
            guard let state = initialTrackingState(frame) else { return nil }
            phase = .tracking(state)

        case .tracking(var state):
            return updateTracking(frame, state: &state)

        case .cancellingUntilRelease:
            if activeTouches.isEmpty {
                phase = .idle
            }
        }

        return nil
    }

    private func trackingAnchor(from touches: [TouchPoint]) -> NormalizedPoint? {
        guard touches.count == rule.fingerCount else { return nil }
        guard let centroid = NormalizedPoint.centroid(of: touches) else { return nil }
        guard rule.region?.contains(centroid) ?? true else { return nil }
        return centroid
    }

    private func initialTrackingState(_ frame: TouchFrame) -> HoldTrackingState? {
        guard let anchor = trackingAnchor(from: frame.activeTouches) else { return nil }
        var forceProgress = ForcePressProgress()
        forceProgress.update(
            timestamp: frame.timestamp,
            pressure: frame.activeTouches.map(\.pressure).max() ?? 0,
            activationThreshold: rule.minimumPressure,
            sustainingThreshold: rule.sustainingPressure,
            clickSatisfied: true
        )
        return HoldTrackingState(
            anchor: anchor,
            clickBaseline: frame.clickGeneration,
            sawClick: frame.hasRecentClick,
            forceProgress: forceProgress
        )
    }

    private func updateTracking(_ frame: TouchFrame, state: inout HoldTrackingState) -> RecognizedGesture? {
        let activeTouches = frame.activeTouches
        if activeTouches.isEmpty {
            return finishOnRelease(frame, state: state)
        }
        guard let centroid = trackingAnchor(from: activeTouches),
              centroid.distance(to: state.anchor) <= rule.maximumMovement else {
            phase = .cancellingUntilRelease
            return nil
        }
        updateClickAndForce(frame, state: &state)
        guard hasHeldLongEnough(frame, state: state) else {
            phase = .tracking(state)
            return nil
        }
        return processHeldFrame(frame, state: &state)
    }

    private func finishOnRelease(_ frame: TouchFrame, state: HoldTrackingState) -> RecognizedGesture? {
        phase = .idle
        guard rule.triggerTiming == .afterRelease, state.armedForRelease, canTrigger(at: frame.timestamp) else {
            return nil
        }
        lastTriggeredAt = frame.timestamp
        return recognizedGesture(frame)
    }

    private func updateClickAndForce(_ frame: TouchFrame, state: inout HoldTrackingState) {
        state.sawClick = state.sawClick || frame.clickGeneration > state.clickBaseline || frame.hasRecentClick
        state.forceProgress.update(
            timestamp: frame.timestamp,
            pressure: frame.activeTouches.map(\.pressure).max() ?? 0,
            activationThreshold: rule.minimumPressure,
            sustainingThreshold: rule.sustainingPressure,
            clickSatisfied: true
        )
    }

    private func processHeldFrame(_ frame: TouchFrame, state: inout HoldTrackingState) -> RecognizedGesture? {
        guard matchesPressRequirement(frame, state: state) else {
            phase = .tracking(state)
            return nil
        }
        switch rule.triggerTiming {
        case .whileTouching:
            return triggerWhileTouching(frame, state: &state)
        case .afterRelease:
            state.armedForRelease = true
            phase = .tracking(state)
            return nil
        }
    }

    private func triggerWhileTouching(_ frame: TouchFrame, state: inout HoldTrackingState) -> RecognizedGesture? {
        guard !state.triggered, canTrigger(at: frame.timestamp) else {
            phase = .tracking(state)
            return nil
        }
        state.triggered = true
        lastTriggeredAt = frame.timestamp
        phase = .tracking(state)
        return recognizedGesture(frame)
    }

    private func matchesPressRequirement(_ frame: TouchFrame, state: HoldTrackingState) -> Bool {
        switch rule.pressKind {
        case .touch:
            return state.forceProgress.startedAt != nil
        case .click:
            return clickEventSatisfied(state) && state.forceProgress.startedAt != nil
        case .forceClick:
            return state.sawClick && state.forceProgress.startedAt != nil
        }
    }

    private func hasHeldLongEnough(_ frame: TouchFrame, state: HoldTrackingState) -> Bool {
        switch rule.pressKind {
        case .touch:
            return state.forceProgress.isSatisfied(
                at: frame.timestamp,
                minimumMilliseconds: rule.holdMilliseconds
            )
        case .click:
            return clickEventSatisfied(state)
                && state.forceProgress.isSatisfied(
                    at: frame.timestamp,
                    minimumMilliseconds: rule.holdMilliseconds
                )
        case .forceClick:
            return state.sawClick
                && state.forceProgress.isSatisfied(
                    at: frame.timestamp,
                    minimumMilliseconds: rule.holdMilliseconds
                )
        }
    }

    private func clickEventSatisfied(_ state: HoldTrackingState) -> Bool {
        rule.fingerCount == 2 || state.sawClick
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        let cooldown = TimeInterval(rule.cooldownMilliseconds) / 1000
        return timestamp - lastTriggeredAt >= cooldown
    }

    private func recognizedGesture(_ frame: TouchFrame) -> RecognizedGesture {
        RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }
}

private enum HoldPhase: Equatable {
    case idle
    case tracking(HoldTrackingState)
    case cancellingUntilRelease
}

private struct HoldTrackingState: Equatable {
    var anchor: NormalizedPoint
    var clickBaseline: UInt64
    var sawClick: Bool
    var forceProgress = ForcePressProgress()
    var triggered = false
    var armedForRelease = false
}
