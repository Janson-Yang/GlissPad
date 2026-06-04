import Foundation

final class TipTapGestureRecognizer {
    private let id: String
    private let rule: TipTapGestureRule
    private let kind: RecognizedGesture.Kind
    private var phase = TipTapPhase.idle
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: TipTapGestureRule, kind: RecognizedGesture.Kind) {
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
            startBaseIfPossible(frame)
        case .base(let base):
            return updateBase(frame, base: base)
        case .tip(let state):
            return updateTip(frame, state: state)
        case .cancellingUntilRelease:
            if frame.activeTouches.isEmpty { phase = .idle }
        }
        return nil
    }

    private func startBaseIfPossible(_ frame: TouchFrame) {
        guard frame.activeTouches.count == 1, let touch = frame.activeTouches.first else { return }
        guard rule.region?.contains(touch.position) ?? true else { return }
        phase = .base(TipTapBase(id: touch.id, anchor: touch.position))
    }

    private func updateBase(_ frame: TouchFrame, base: TipTapBase) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard let baseTouch = touch(id: base.id, in: active),
              baseTouch.position.distance(to: base.anchor) <= rule.stationaryMovement else {
            phase = active.isEmpty ? .idle : .cancellingUntilRelease
            return nil
        }
        if active.count == 1 {
            phase = .base(base)
            return nil
        }
        guard active.count == 2,
              let tipTouch = active.first(where: { $0.id != base.id }),
              activeFingerAllowed(tipTouch, touches: active) else {
            phase = .cancellingUntilRelease
            return nil
        }
        phase = .tip(TipTapState(base: base, tipID: tipTouch.id, tipAnchor: tipTouch.position, startedAt: frame.timestamp))
        return nil
    }

    private func updateTip(_ frame: TouchFrame, state: TipTapState) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard let baseTouch = touch(id: state.base.id, in: active),
              baseTouch.position.distance(to: state.base.anchor) <= rule.stationaryMovement else {
            phase = active.isEmpty ? .idle : .cancellingUntilRelease
            return nil
        }
        if active.count == 1 {
            return finishTip(frame, state: state)
        }
        guard active.count == 2,
              let tipTouch = touch(id: state.tipID, in: active),
              tipTouch.position.distance(to: state.tipAnchor) <= rule.tapMovement else {
            phase = .cancellingUntilRelease
            return nil
        }
        phase = .tip(state)
        return nil
    }

    private func finishTip(_ frame: TouchFrame, state: TipTapState) -> RecognizedGesture? {
        phase = .base(state.base)
        let duration = frame.timestamp - state.startedAt
        guard duration <= TimeInterval(rule.maximumTapMilliseconds) / 1000,
              canTrigger(at: frame.timestamp) else {
            return nil
        }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func touch(id: Int, in touches: [TouchPoint]) -> TouchPoint? {
        touches.first { $0.id == id }
    }

    private func activeFingerAllowed(_ touch: TouchPoint, touches: [TouchPoint]) -> Bool {
        switch rule.activeFinger {
        case .auto:
            return true
        case .left:
            return touches.sortedByHorizontalPosition().first?.id == touch.id
        case .right:
            return touches.sortedByHorizontalPosition().last?.id == touch.id
        }
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }
}

private struct TipTapBase: Equatable {
    var id: Int
    var anchor: NormalizedPoint
}

private struct TipTapState: Equatable {
    var base: TipTapBase
    var tipID: Int
    var tipAnchor: NormalizedPoint
    var startedAt: TimeInterval
}

private enum TipTapPhase: Equatable {
    case idle
    case base(TipTapBase)
    case tip(TipTapState)
    case cancellingUntilRelease
}
