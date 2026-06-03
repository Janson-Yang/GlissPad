import Foundation

final class CornerClickGestureRecognizer {
    private let id: String
    private let rule: CornerClickGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = CornerClickPhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: CornerClickGestureRule, kind: RecognizedGesture.Kind) {
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
        guard rule.region.contains(touch.position) else { return }
        phase = .tracking(CornerClickState(
            anchor: touch.position,
            clickBaseline: frame.clickGeneration,
            sawClick: frame.hasRecentClick,
            forceProgress: forceProgress(frame, touch: touch)
        ))
    }

    private func updateTracking(_ frame: TouchFrame, state: inout CornerClickState) -> RecognizedGesture? {
        if frame.activeTouches.isEmpty {
            return finishOnRelease(frame, state: state)
        }
        guard let touch = singleTouch(in: frame.activeTouches) else {
            phase = .cancellingUntilRelease
            return nil
        }
        guard touch.position.distance(to: state.anchor) <= rule.maximumMovement else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.sawClick = state.sawClick || observedSystemClick(frame, state: state)
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

    private func finishOnRelease(_ frame: TouchFrame, state: CornerClickState) -> RecognizedGesture? {
        phase = .idle
        guard frame.activeTouches.isEmpty, canTrigger(at: frame.timestamp), matchesClickKind(frame, state: state) else {
            return nil
        }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func matchesClickKind(_ frame: TouchFrame, state: CornerClickState) -> Bool {
        let pressureSatisfied = state.forceProgress.isSatisfied(
            at: frame.timestamp,
            minimumMilliseconds: rule.minimumForceMilliseconds
        )
        switch rule.clickKind {
        case .tap:
            return !state.sawClick && !observedSystemClick(frame, state: state)
        case .click:
            return observedSystemClick(frame, state: state) || state.sawClick || pressureSatisfied
        case .forceClick:
            return pressureSatisfied
        }
    }

    private func singleTouch(in touches: [TouchPoint]) -> TouchPoint? {
        touches.count == 1 ? touches[0] : nil
    }

    private func forceProgress(_ frame: TouchFrame, touch: TouchPoint) -> ForcePressProgress {
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

    private func observedSystemClick(_ frame: TouchFrame, state: CornerClickState) -> Bool {
        frame.clickGeneration > state.clickBaseline || frame.hasRecentClick
    }
}

private struct CornerClickState: Equatable {
    var anchor: NormalizedPoint
    var clickBaseline: UInt64
    var sawClick: Bool
    var forceProgress: ForcePressProgress
}

private enum CornerClickPhase: Equatable {
    case idle
    case tracking(CornerClickState)
    case cancellingUntilRelease
}
