import Foundation

final class OneFingerPressGestureRecognizer {
    private let id: String
    private let rule: OneFingerPressGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = OneFingerPressPhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: OneFingerPressGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
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
        guard let touch = singleTouch(in: frame.activeTouches) else { return }
        phase = .tracking(OneFingerPressState(
            anchor: touch.position,
            clickBaseline: frame.clickGeneration,
            sawClick: frame.hasRecentClick,
            forceProgress: forceProgress(frame, touch: touch, sawClick: frame.hasRecentClick)
        ))
    }

    private func updateTracking(_ frame: TouchFrame, state: inout OneFingerPressState) -> RecognizedGesture? {
        if frame.activeTouches.isEmpty {
            return finishOnRelease(frame, state: state)
        }
        guard let touch = singleTouch(in: frame.activeTouches),
              touch.position.distance(to: state.anchor) <= rule.maximumMovement else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.sawClick = state.sawClick || frame.clickGeneration > state.clickBaseline || frame.hasRecentClick
        state.forceProgress.update(
            timestamp: frame.timestamp,
            pressure: touch.pressure,
            activationThreshold: rule.minimumPressure,
            sustainingThreshold: rule.sustainingPressure,
            clickSatisfied: true
        )
        phase = .tracking(state)
        return nil
    }

    private func finishOnRelease(_ frame: TouchFrame, state: OneFingerPressState) -> RecognizedGesture? {
        phase = .idle
        guard canTrigger(at: frame.timestamp), matchesPressKind(frame, state: state) else {
            return nil
        }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func matchesPressKind(_ frame: TouchFrame, state: OneFingerPressState) -> Bool {
        switch rule.pressKind {
        case .click:
            return state.sawClick
                && state.forceProgress.isSatisfied(
                    at: frame.timestamp,
                    minimumMilliseconds: rule.minimumForceMilliseconds
                )
        case .forceClick:
            return state.sawClick
                && state.forceProgress.isSatisfied(
                    at: frame.timestamp,
                    minimumMilliseconds: rule.minimumForceMilliseconds
                )
        }
    }

    private func singleTouch(in touches: [TouchPoint]) -> TouchPoint? {
        touches.count == 1 ? touches[0] : nil
    }

    private func forceProgress(_ frame: TouchFrame, touch: TouchPoint, sawClick: Bool) -> ForcePressProgress {
        var progress = ForcePressProgress()
        progress.update(
            timestamp: frame.timestamp,
            pressure: touch.pressure,
            activationThreshold: rule.minimumPressure,
            sustainingThreshold: rule.sustainingPressure,
            clickSatisfied: true
        )
        return progress
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }
}

private struct OneFingerPressState: Equatable {
    var anchor: NormalizedPoint
    var clickBaseline: UInt64
    var sawClick: Bool
    var forceProgress: ForcePressProgress
}

private enum OneFingerPressPhase: Equatable {
    case idle
    case tracking(OneFingerPressState)
    case cancellingUntilRelease
}
