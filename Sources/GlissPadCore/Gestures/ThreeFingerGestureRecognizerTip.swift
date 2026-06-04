import Foundation

extension ThreeFingerGestureRecognizer {
    func processTipTap(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle:
            startTipBaseIfPossible(frame)
        case .tipBase(let base):
            return updateTipBase(frame, base: base, swipe: false)
        case .tip(let state):
            return updateTipTap(frame, state: state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    func processTipSwipe(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle:
            startTipBaseIfPossible(frame)
        case .tipBase(let base):
            return updateTipBase(frame, base: base, swipe: true)
        case .tip(var state):
            return updateTipSwipe(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    private func startTipBaseIfPossible(_ frame: TouchFrame) {
        let active = frame.activeTouches
        guard active.count == 2, regionContains(rule.common.region, touches: active) else { return }
        phase = .tipBase(ThreeFingerTipBase(
            anchors: Dictionary(uniqueKeysWithValues: active.map { ($0.id, $0.position) }),
            startedAt: frame.timestamp
        ))
    }

    private func updateTipBase(
        _ frame: TouchFrame,
        base: ThreeFingerTipBase,
        swipe: Bool
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        if active.isEmpty {
            phase = .idle
            return nil
        }
        guard fixedTouchesAreStable(active, base: base, swipe: swipe) else {
            phase = .cancellingUntilRelease
            return nil
        }
        guard active.count == 3 else {
            phase = .tipBase(base)
            return nil
        }
        let hold = swipe ? rule.tipSwipe.minimumFixedFingerHoldMilliseconds : rule.tipTap.minimumFixedFingerHoldMilliseconds
        guard frame.timestamp - base.startedAt >= TimeInterval(hold) / 1000,
              let activeTouch = active.first(where: { base.anchors[$0.id] == nil }) else {
            phase = .tipBase(base)
            return nil
        }
        guard activeFingerAllowed(activeTouch, touches: active, swipe: swipe) else {
            phase = .cancellingUntilRelease
            return nil
        }
        phase = .tip(ThreeFingerTipState(
            base: base,
            activeID: activeTouch.id,
            activeAnchor: activeTouch.position,
            startedAt: frame.timestamp
        ))
        return nil
    }

    private func updateTipTap(_ frame: TouchFrame, state: ThreeFingerTipState) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard fixedTouchesAreStable(active, base: state.base, swipe: false) else {
            phase = active.isEmpty ? .idle : .cancellingUntilRelease
            return nil
        }
        if active.count == 2 { return finishTipTap(frame, state: state) }
        guard active.count == 3,
              let tip = active.first(where: { $0.id == state.activeID }),
              tip.position.distance(to: state.activeAnchor) <= rule.tipTap.maximumActiveFingerMovement else {
            phase = .cancellingUntilRelease
            return nil
        }
        phase = .tip(state)
        return nil
    }

    private func finishTipTap(_ frame: TouchFrame, state: ThreeFingerTipState) -> RecognizedGesture? {
        phase = .tipBase(state.base)
        guard frame.timestamp - state.startedAt <= TimeInterval(rule.tipTap.maximumTapMilliseconds) / 1000,
              canTrigger(at: frame.timestamp) else {
            return nil
        }
        return recognizedGesture(frame)
    }

    private func updateTipSwipe(
        _ frame: TouchFrame,
        state: inout ThreeFingerTipState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        guard fixedTouchesAreStable(active, base: state.base, swipe: true) else {
            phase = active.isEmpty ? .idle : .cancellingUntilRelease
            return nil
        }
        guard let tip = active.first(where: { $0.id == state.activeID }) else {
            return finishTipSwipe(frame, state: state)
        }
        state.completed = state.completed || tipSwipeCompleted(frame: frame, state: state, tip: tip)
        return triggerTipSwipeIfNeeded(frame, state: &state)
    }

    private func fixedTouchesAreStable(_ active: [TouchPoint], base: ThreeFingerTipBase, swipe: Bool) -> Bool {
        let tolerance = swipe ? rule.tipSwipe.maximumFixedFingerMovement : rule.tipTap.maximumFixedFingerMovement
        return base.anchors.allSatisfy { id, anchor in
            guard let touch = active.first(where: { $0.id == id }) else { return false }
            return touch.position.distance(to: anchor) <= tolerance
        }
    }

    private func activeFingerAllowed(_ touch: TouchPoint, touches: [TouchPoint], swipe: Bool) -> Bool {
        let expected = swipe ? rule.tipSwipe.activeFinger.position : rule.tipTap.tapPosition
        let reference = swipe ? rule.tipSwipe.activeFingerReference : rule.tipTap.positionReference
        guard expected != nil else { return true }
        let sorted = reference == .trackpad ? touches.sortedByHorizontalPosition() : touches.sorted { $0.id < $1.id }
        return sorted[safe: expected!.index]?.id == touch.id
    }
}

private extension ThreeFingerActiveFinger {
    var position: ThreeFingerPosition? {
        switch self {
        case .auto: return nil
        case .left: return .left
        case .middle: return .middle
        case .right: return .right
        }
    }
}

private extension ThreeFingerPosition {
    var index: Int {
        switch self {
        case .left: return 0
        case .middle: return 1
        case .right: return 2
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
