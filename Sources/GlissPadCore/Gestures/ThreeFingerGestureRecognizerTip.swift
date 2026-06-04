import Foundation

extension ThreeFingerGestureRecognizer {
    func processTipTap(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle:
            startTipBaseIfPossible(frame, swipe: false)
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
            startTipSwipeIfPossible(frame)
        case .tipBase(let base):
            return updateTipBase(frame, base: base, swipe: true)
        case .tipCandidate(let candidate):
            return updateTipSwipeCandidate(frame, candidate: candidate)
        case .tip(var state):
            return updateTipSwipe(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    private func startTipSwipeIfPossible(_ frame: TouchFrame) {
        let active = frame.activeTouches
        let fixedFingers = rule.tipSwipe.fixedFingers
        if active.count == fixedFingers {
            startTipBaseIfPossible(frame, swipe: true)
        } else if active.count == fixedFingers + 1, regionContains(rule.common.region, touches: active) {
            phase = .tipCandidate(ThreeFingerTipCandidateState(
                anchors: Dictionary(uniqueKeysWithValues: active.map { ($0.id, $0.position) }),
                startedAt: frame.timestamp
            ))
        }
    }

    private func startTipBaseIfPossible(_ frame: TouchFrame, swipe: Bool) {
        let active = frame.activeTouches
        let fixedFingers = swipe ? rule.tipSwipe.fixedFingers : rule.tipTap.fixedFingers
        guard active.count == fixedFingers, regionContains(rule.common.region, touches: active) else { return }
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
        guard active.count == base.anchors.count + 1 else {
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

    private func updateTipSwipeCandidate(
        _ frame: TouchFrame,
        candidate: ThreeFingerTipCandidateState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        if active.isEmpty {
            phase = .idle
            return nil
        }
        guard active.count == candidate.anchors.count,
              let state = promotedTipSwipeCandidate(candidate, touches: active, frame: frame) else {
            phase = active.count == candidate.anchors.count ? .tipCandidate(candidate) : .cancellingUntilRelease
            return nil
        }
        var nextState = state
        return updateTipSwipe(frame, state: &nextState)
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
        guard frame.timestamp - state.startedAt <= TimeInterval(rule.tipTap.maximumTapMilliseconds) / 1000 else {
            return nil
        }
        return recordTipTap(frame, anchor: state.activeAnchor)
    }

    private func recordTipTap(_ frame: TouchFrame, anchor: NormalizedPoint) -> RecognizedGesture? {
        guard rule.tipTap.tapCount > 1 else {
            return canTrigger(at: frame.timestamp) ? recognizedGesture(frame) : nil
        }
        let previous = pendingTap
        let nextCount = validPendingTipTap(previous, frame: frame, anchor: anchor) ? previous!.count + 1 : 1
        pendingTap = ThreeFingerPendingTap(count: nextCount, timestamp: frame.timestamp, anchor: anchor)
        guard nextCount >= rule.tipTap.tapCount else { return nil }
        pendingTap = nil
        return canTrigger(at: frame.timestamp) ? recognizedGesture(frame) : nil
    }

    private func validPendingTipTap(
        _ pending: ThreeFingerPendingTap?,
        frame: TouchFrame,
        anchor: NormalizedPoint
    ) -> Bool {
        guard let pending else { return false }
        let interval = TimeInterval(rule.tap.maximumInterTapIntervalMilliseconds) / 1000
        return frame.timestamp - pending.timestamp <= interval
            && pending.anchor.distance(to: anchor) <= rule.tipTap.maximumActiveFingerMovement
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

    private func promotedTipSwipeCandidate(
        _ candidate: ThreeFingerTipCandidateState,
        touches: [TouchPoint],
        frame: TouchFrame
    ) -> ThreeFingerTipState? {
        let movements = tipCandidateMovements(candidate, touches: touches)
        guard let activeMovement = movements.first,
              activeMovement.distance >= tipSwipeMovementStartDistance else { return nil }
        let fixedMovements = movements.dropFirst()
        guard fixedMovements.count == rule.tipSwipe.fixedFingers,
              fixedMovements.allSatisfy({ $0.distance <= rule.tipSwipe.maximumFixedFingerMovement }),
              activeFingerAllowed(activeMovement.touch, touches: touches, swipe: true) else {
            return nil
        }
        let base = ThreeFingerTipBase(
            anchors: Dictionary(uniqueKeysWithValues: fixedMovements.map { ($0.touch.id, $0.anchor) }),
            startedAt: candidate.startedAt
        )
        return ThreeFingerTipState(
            base: base,
            activeID: activeMovement.touch.id,
            activeAnchor: activeMovement.anchor,
            startedAt: frame.timestamp
        )
    }

    private func tipCandidateMovements(
        _ candidate: ThreeFingerTipCandidateState,
        touches: [TouchPoint]
    ) -> [(touch: TouchPoint, anchor: NormalizedPoint, distance: Double)] {
        touches.compactMap { touch in
            guard let anchor = candidate.anchors[touch.id] else { return nil }
            return (touch, anchor, touch.position.distance(to: anchor))
        }
        .sorted { first, second in
            if first.distance == second.distance { return first.touch.id < second.touch.id }
            return first.distance > second.distance
        }
    }

    private var tipSwipeMovementStartDistance: Double {
        min(rule.tipSwipe.minimumTravel * 0.5, max(0.015, rule.tipSwipe.maximumFixedFingerMovement * 0.5))
    }

    private func fixedTouchesAreStable(_ active: [TouchPoint], base: ThreeFingerTipBase, swipe: Bool) -> Bool {
        let tolerance = swipe ? rule.tipSwipe.maximumFixedFingerMovement : rule.tipTap.maximumFixedFingerMovement
        return base.anchors.allSatisfy { id, anchor in
            guard let touch = active.first(where: { $0.id == id }) else { return false }
            return touch.position.distance(to: anchor) <= tolerance
        }
    }

    private func activeFingerAllowed(_ touch: TouchPoint, touches: [TouchPoint], swipe: Bool) -> Bool {
        let selected = swipe ? rule.tipSwipe.activeFinger : rule.tipTap.tapPosition
        let reference = swipe ? rule.tipSwipe.activeFingerReference : rule.tipTap.positionReference
        guard selected != .auto, let index = activeFingerIndex(selected, touchCount: touches.count) else {
            return selected == .auto
        }
        let ordered = activeFingerCandidates(touches: touches, reference: reference)
        return ordered[safe: index] == touch.id
    }

    private func activeFingerIndex(_ finger: ThreeFingerActiveFinger, touchCount: Int) -> Int? {
        switch finger {
        case .auto: return nil
        case .left: return 0
        case .middle: return touchCount == 3 ? 1 : nil
        case .right: return touchCount - 1
        }
    }

    private func activeFingerCandidates(
        touches: [TouchPoint],
        reference: ThreeFingerFingerReference
    ) -> [Int] {
        if reference == .trackpad { return touches.sortedByHorizontalPosition().map(\.id) }
        return touches.map(\.id)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
