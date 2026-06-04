import Foundation

public final class GestureRecognizer: @unchecked Sendable {
    private let configuration: GestureConfiguration
    private var oneFingerRecognizers: [String: OneFingerGestureRecognizer] = [:]
    private var circleRecognizers: [String: CircleGestureRecognizer] = [:]
    private var shapeRecognizers: [String: ShapeGestureRecognizer] = [:]
    private var cornerClickRecognizers: [String: CornerClickGestureRecognizer] = [:]
    private var tapRecognizers: [String: TapGestureRecognizer] = [:]
    private var oneFingerPressRecognizers: [String: OneFingerPressGestureRecognizer] = [:]
    private var customPathRecognizers: [String: CustomPathGestureRecognizer] = [:]
    private var touchStartRecognizers: [String: TouchStartGestureRecognizer] = [:]
    private var tipTapRecognizers: [String: TipTapGestureRecognizer] = [:]
    private var transformRecognizers: [String: TwoFingerTransformGestureRecognizer] = [:]
    private var multiFingerSwipeRecognizers: [String: MultiFingerSwipeGestureRecognizer] = [:]
    private var pressStates: [String: PressRecognitionState] = [:]
    private var swipeRecognizers: [String: SwipeGestureRecognizer] = [:]
    private var holdRecognizers: [String: HoldGestureRecognizer] = [:]
    private var releaseRecognizers: [String: ReleaseGestureRecognizer] = [:]
    private var threeFingerRecognizers: [String: ThreeFingerGestureRecognizer] = [:]

    public init(configuration: GestureConfiguration) {
        self.configuration = configuration
        for trigger in configuration.triggers {
            addState(for: trigger)
        }
    }

    public func process(_ frame: TouchFrame) -> [RecognizedGesture] {
        let recognized = configuration.triggers.compactMap { trigger in
            process(trigger, frame: frame)
        }
        return prioritized(recognized)
    }

    func processTimer(at timestamp: TimeInterval) -> [RecognizedGesture] {
        let recognized = configuration.triggers.compactMap { trigger in
            processTimer(trigger, timestamp: timestamp)
        }
        return prioritized(recognized)
    }

    func nextTimerDeadline() -> TimeInterval? {
        configuration.triggers.compactMap(nextTimerDeadline).min()
    }

    private func addState(for trigger: GestureRule) {
        switch trigger {
        case .oneFinger(let id, let type, let rule):
            oneFingerRecognizers[id] = OneFingerGestureRecognizer(id: id, rule: rule, kind: type)
        case .circle(let id, let type, let rule):
            circleRecognizers[id] = CircleGestureRecognizer(id: id, rule: rule, kind: type)
        case .shape(let id, let type, let rule):
            shapeRecognizers[id] = ShapeGestureRecognizer(id: id, rule: rule, kind: type)
        case .cornerClick(let id, let type, let rule):
            cornerClickRecognizers[id] = CornerClickGestureRecognizer(id: id, rule: rule, kind: type)
        case .tap(let id, let type, let rule):
            tapRecognizers[id] = TapGestureRecognizer(id: id, rule: rule, kind: type)
        case .oneFingerPress(let id, let type, let rule):
            oneFingerPressRecognizers[id] = OneFingerPressGestureRecognizer(id: id, rule: rule, kind: type)
        case .customPath(let id, let type, let rule):
            customPathRecognizers[id] = CustomPathGestureRecognizer(id: id, rule: rule, kind: type)
        case .touchStart(let id, let type, let rule):
            touchStartRecognizers[id] = TouchStartGestureRecognizer(id: id, rule: rule, kind: type)
        case .tipTap(let id, let type, let rule):
            tipTapRecognizers[id] = TipTapGestureRecognizer(id: id, rule: rule, kind: type)
        case .transform(let id, let type, let rule):
            transformRecognizers[id] = TwoFingerTransformGestureRecognizer(id: id, rule: rule, kind: type)
        case .multiFingerSwipe(let id, let type, let rule):
            multiFingerSwipeRecognizers[id] = MultiFingerSwipeGestureRecognizer(id: id, rule: rule, kind: type)
        case .press(let id, _, _):
            pressStates[id] = PressRecognitionState()
        case .swipe(let id, let type, let rule):
            swipeRecognizers[id] = SwipeGestureRecognizer(id: id, rule: rule, kind: type)
        case .hold(let id, let type, let rule):
            holdRecognizers[id] = HoldGestureRecognizer(id: id, rule: rule, kind: type)
        case .release(let id, let type, let rule):
            releaseRecognizers[id] = ReleaseGestureRecognizer(id: id, rule: rule, kind: type)
        case .threeFinger(let id, let type, let rule):
            threeFingerRecognizers[id] = ThreeFingerGestureRecognizer(id: id, type: type, rule: rule)
        }
    }

    private func process(_ trigger: GestureRule, frame: TouchFrame) -> RecognizedGesture? {
        switch trigger {
        case .oneFinger(let id, _, _):
            return oneFingerRecognizers[id]?.process(frame)
        case .circle(let id, _, _):
            return circleRecognizers[id]?.process(frame)
        case .shape(let id, _, _):
            return shapeRecognizers[id]?.process(frame)
        case .cornerClick(let id, _, _):
            return cornerClickRecognizers[id]?.process(frame)
        case .tap(let id, _, _):
            return tapRecognizers[id]?.process(frame)
        case .oneFingerPress(let id, _, _):
            return oneFingerPressRecognizers[id]?.process(frame)
        case .customPath(let id, _, _):
            return customPathRecognizers[id]?.process(frame)
        case .touchStart(let id, _, _):
            return touchStartRecognizers[id]?.process(frame)
        case .tipTap(let id, _, _):
            return tipTapRecognizers[id]?.process(frame)
        case .transform(let id, _, _):
            return transformRecognizers[id]?.process(frame)
        case .multiFingerSwipe(let id, _, _):
            return multiFingerSwipeRecognizers[id]?.process(frame)
        case .press(let id, let type, let rule):
            var state = pressStates[id] ?? PressRecognitionState()
            defer { pressStates[id] = state }
            return evaluate(id: id, rule: rule, kind: type, frame: frame, state: &state)
        case .swipe(let id, _, _):
            return swipeRecognizers[id]?.process(frame)
        case .hold(let id, _, _):
            return holdRecognizers[id]?.process(frame)
        case .release(let id, _, _):
            return releaseRecognizers[id]?.process(frame)
        case .threeFinger(let id, _, _):
            return threeFingerRecognizers[id]?.process(frame)
        }
    }

    private func processTimer(_ trigger: GestureRule, timestamp: TimeInterval) -> RecognizedGesture? {
        guard case .threeFinger(let id, _, _) = trigger else { return nil }
        return threeFingerRecognizers[id]?.processTimer(at: timestamp)
    }

    private func nextTimerDeadline(_ trigger: GestureRule) -> TimeInterval? {
        guard case .threeFinger(let id, _, _) = trigger else { return nil }
        return threeFingerRecognizers[id]?.nextTimerDeadline()
    }

    private func prioritized(_ gestures: [RecognizedGesture]) -> [RecognizedGesture] {
        let threeFinger = gestures.filter { $0.kind.isThreeFingerGestureFamily }
        guard let winner = threeFinger.max(by: { $0.kind.threeFingerPriority < $1.kind.threeFingerPriority }) else {
            return gestures
        }
        return gestures.filter { !$0.kind.isThreeFingerGestureFamily } + [winner]
    }

    private func evaluate(
        id: String,
        rule: PressGestureRule,
        kind: RecognizedGesture.Kind,
        frame: TouchFrame,
        state: inout PressRecognitionState
    ) -> RecognizedGesture? {
        guard rule.isEnabled else {
            state.phase = .idle
            return nil
        }
        let activeTouches = frame.activeTouches
        let matchingContact = matchesContact(rule, touches: activeTouches)

        switch state.phase {
        case .idle:
            guard matchingContact else { return nil }
            let sawClick = !rule.requiresClick || frame.hasRecentClick
            var forceProgress = ForcePressProgress()
            forceProgress.update(
                timestamp: frame.timestamp,
                pressure: maximumPressure(in: frame),
                activationThreshold: rule.minimumPressure,
                sustainingThreshold: rule.sustainingPressure,
                clickSatisfied: true
            )
            state.anchor = NormalizedPoint.centroid(of: activeTouches)
            state.phase = .possible(
                forceProgress: forceProgress,
                clickBaseline: frame.clickGeneration,
                sawClick: sawClick
            )
        case .possible(let forceProgress, let clickBaseline, let sawClick):
            updatePossibleState(
                rule: rule,
                frame: frame,
                forceProgress: forceProgress,
                clickBaseline: clickBaseline,
                sawClick: sawClick,
                state: &state
            )
        case .armed(let clickBaseline, let sawClick):
            return processArmed(
                id: id,
                rule: rule,
                kind: kind,
                frame: frame,
                clickBaseline: clickBaseline,
                sawClick: sawClick,
                state: &state
            )
        case .cancellingUntilRelease:
            resetIfReleased(frame: frame, state: &state)
        }
        return nil
    }

    private func updatePossibleState(
        rule: PressGestureRule,
        frame: TouchFrame,
        forceProgress: ForcePressProgress,
        clickBaseline: UInt64,
        sawClick: Bool,
        state: inout PressRecognitionState
    ) {
        let activeTouches = frame.activeTouches
        guard !activeTouches.isEmpty else {
            state.phase = .idle
            state.anchor = nil
            return
        }
        guard matchesContact(rule, touches: activeTouches),
              !state.exceededMovementLimit(with: activeTouches, rule: rule) else {
            state.phase = .cancellingUntilRelease
            return
        }
        let updatedSawClick = sawClick || frame.clickGeneration > clickBaseline || frame.hasRecentClick
        var newForceProgress = forceProgress
        newForceProgress.update(
            timestamp: frame.timestamp,
            pressure: maximumPressure(in: frame),
            activationThreshold: rule.minimumPressure,
            sustainingThreshold: rule.sustainingPressure,
            clickSatisfied: true
        )
        state.phase = phaseAfterPossibleForce(
            rule: rule,
            frame: frame,
            forceProgress: newForceProgress,
            clickBaseline: clickBaseline,
            sawClick: updatedSawClick
        )
    }

    private func processArmed(
        id: String,
        rule: PressGestureRule,
        kind: RecognizedGesture.Kind,
        frame: TouchFrame,
        clickBaseline: UInt64,
        sawClick: Bool,
        state: inout PressRecognitionState
    ) -> RecognizedGesture? {
        let activeTouches = frame.activeTouches
        let updatedSawClick = sawClick || frame.clickGeneration > clickBaseline || frame.hasRecentClick
        if activeTouches.isEmpty {
            state.phase = .idle
            state.anchor = nil
            guard updatedSawClick, state.canTrigger(at: frame.timestamp, rule: rule) else { return nil }
            state.recordTrigger(at: frame.timestamp)
            return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
        }
        if activeTouches.count > rule.fingerCount || movedTooFar(rule: rule, touches: activeTouches, state: state) {
            state.phase = .cancellingUntilRelease
        }
        return nil
    }

    private func movedTooFar(rule: PressGestureRule, touches: [TouchPoint], state: PressRecognitionState) -> Bool {
        touches.count == rule.fingerCount && state.exceededMovementLimit(with: touches, rule: rule)
    }

    private func resetIfReleased(frame: TouchFrame, state: inout PressRecognitionState) {
        guard frame.activeTouches.isEmpty else { return }
        state.phase = .idle
        state.anchor = nil
    }

    private func matchesContact(_ rule: PressGestureRule, touches: [TouchPoint]) -> Bool {
        guard touches.count == rule.fingerCount else { return false }
        guard let region = rule.region else { return true }
        guard let centroid = NormalizedPoint.centroid(of: touches) else { return false }
        return region.contains(centroid)
    }

    private func maximumPressure(in frame: TouchFrame) -> Double {
        frame.activeTouches.map(\.pressure).max() ?? 0
    }

    private func phaseAfterPossibleForce(
        rule: PressGestureRule,
        frame: TouchFrame,
        forceProgress: ForcePressProgress,
        clickBaseline: UInt64,
        sawClick: Bool
    ) -> PressPhase {
        if forceProgress.isSatisfied(at: frame.timestamp, minimumMilliseconds: rule.minimumForceMilliseconds) {
            return .armed(clickBaseline: clickBaseline, sawClick: sawClick)
        }
        return .possible(forceProgress: forceProgress, clickBaseline: clickBaseline, sawClick: sawClick)
    }
}
