import Foundation

final class ThreeFingerGestureRecognizer {
    let id: String
    let type: GestureTriggerType
    let rule: ThreeFingerGestureRule
    let requiredFingerCount: Int
    var phase = ThreeFingerRecognitionPhase.idle
    var pendingTap: ThreeFingerPendingTap?
    var lastTriggeredAt: TimeInterval?

    init(id: String, type: GestureTriggerType, rule: ThreeFingerGestureRule, requiredFingerCount: Int = 3) {
        self.id = id
        self.type = type
        self.rule = rule
        self.requiredFingerCount = requiredFingerCount
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            reset()
            return nil
        }
        expirePendingTapIfNeeded(at: frame.timestamp)
        switch type {
        case .threeFingerTouch, .fourFingerTouch, .fiveFingerTouch:
            return processTouch(frame)
        case .threeFingerTap, .fourFingerTap, .fiveFingerTap:
            return processTap(frame)
        case .threeFingerPress, .fourFingerPress, .fiveFingerPress:
            return processPress(frame)
        case .threeFingerSwipe, .fourFingerSwipe, .fiveFingerSwipe:
            return processSwipe(frame)
        case .threeFingerTipTap:
            return processTipTap(frame)
        case .threeFingerTipSwipe:
            return processTipSwipe(frame)
        case .fourFingerTipTap:
            return processTipTap(frame)
        case .thumbTwoFingerScale, .thumbThreeFingerScale, .thumbFourFingerScale:
            return processScale(frame)
        case .threeFingerDrawing, .fourFingerDrawing, .fiveFingerDrawing:
            return processDrawing(frame)
        default:
            return nil
        }
    }

    func processTimer(at timestamp: TimeInterval) -> RecognizedGesture? {
        guard rule.isEnabled else {
            reset()
            return nil
        }
        switch type {
        case .threeFingerTouch, .fourFingerTouch, .fiveFingerTouch:
            return processTouchTimer(at: timestamp)
        default:
            return nil
        }
    }

    func nextTimerDeadline() -> TimeInterval? {
        guard rule.isEnabled else { return nil }
        switch type {
        case .threeFingerTouch, .fourFingerTouch, .fiveFingerTouch:
            return nextTouchDeadline()
        default:
            return nil
        }
    }

    func startTrackingIfPossible(_ frame: TouchFrame, region: NormalizedRegion?) {
        let active = frame.activeTouches
        guard !active.isEmpty else {
            phase = .idle
            return
        }
        if isLongTouch, active.count < requiredFingerCount {
            phase = .collecting(currentCollection(frame: frame, active: active))
            return
        }
        var collection = currentCollection(frame: frame, active: active)
        guard isLongTouch || frame.timestamp - collection.startedAt <= effectiveCommonTimeGap else {
            phase = .cancellingUntilRelease
            return
        }
        guard active.count == requiredFingerCount else {
            phase = .collecting(collection)
            return
        }
        guard regionContains(region, touches: active) else {
            phase = .cancellingUntilRelease
            return
        }
        let stableSince = collection.threeFingerStartedAt ?? frame.timestamp
        let stableFrame = collection.threeFingerFrame ?? frame
        let stableTouches = collection.threeFingerTouches ?? active
        guard frame.timestamp - stableSince >= stableFingerDuration else {
            collection.threeFingerStartedAt = stableSince
            collection.threeFingerFrame = stableFrame
            collection.threeFingerTouches = stableTouches
            phase = .collecting(collection)
            return
        }
        phase = .tracking(ThreeFingerTrackingState(frame: frame, touches: active, collection: collection))
    }

    func recognizedGesture(_ frame: TouchFrame) -> RecognizedGesture {
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: type, name: rule.name, actions: rule.actions, frame: frame)
    }

    func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }

    func resetIfReleased(_ frame: TouchFrame) {
        if frame.activeTouches.isEmpty { phase = .idle }
    }

    func reset() {
        phase = .idle
        pendingTap = nil
    }

    var commonTimeGap: TimeInterval { TimeInterval(rule.common.maxInitialFingerTimeGapMilliseconds) / 1000 }

    var stableFingerDuration: TimeInterval { TimeInterval(rule.common.minStableFingerCountDurationMilliseconds) / 1000 }

    private var effectiveCommonTimeGap: TimeInterval {
        let needsRelaxedCollection = (type == .threeFingerDrawing || type == .fourFingerDrawing || type == .fiveFingerDrawing)
            || ((type == .threeFingerTouch || type == .fourFingerTouch || type == .fiveFingerTouch)
                && rule.touch.event == .longTouch)
        return needsRelaxedCollection ? max(commonTimeGap, 0.35) : commonTimeGap
    }

    private var isLongTouch: Bool {
        (type == .threeFingerTouch || type == .fourFingerTouch || type == .fiveFingerTouch)
            && rule.touch.event == .longTouch
    }

    private func currentCollection(frame: TouchFrame, active: [TouchPoint]) -> ThreeFingerCollectionState {
        var collection: ThreeFingerCollectionState
        if case .collecting(let existingCollection) = phase {
            collection = existingCollection
        } else {
            collection = ThreeFingerCollectionState(frame: frame)
        }
        collection.record(frame: frame, active: active, requiredFingerCount: requiredFingerCount)
        return collection
    }

    func regionContains(_ region: NormalizedRegion?, touches: [TouchPoint]) -> Bool {
        guard let region else { return true }
        guard let centroid = NormalizedPoint.centroid(of: touches) else { return false }
        return region.contains(centroid)
    }

    func updateClickState(_ frame: TouchFrame, state: inout ThreeFingerTrackingState) {
        state.sawClick = state.sawClick || frame.hasRecentClick || frame.clickGeneration > state.clickBaseline
    }

    func hasPressed(_ frame: TouchFrame, baseline: UInt64) -> Bool {
        frame.hasRecentClick || frame.clickGeneration > baseline
    }

    func movedBeyondAnchors(_ touches: [TouchPoint], anchors: [Int: NormalizedPoint], tolerance: Double) -> Bool {
        touches.contains { touch in
            guard let anchor = anchors[touch.id] else { return true }
            return touch.position.distance(to: anchor) > tolerance
        }
    }

    func pathLength(_ points: [NormalizedPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        return zip(points, points.dropFirst()).map { $0.distance(to: $1) }.reduce(0, +)
    }

    func displacement(from start: NormalizedPoint, to end: NormalizedPoint) -> (dx: Double, dy: Double) {
        (dx: end.x - start.x, dy: end.y - start.y)
    }

    func directionMatches(dx: Double, dy: Double, direction: ThreeFingerDirection, toleranceDegrees: Double) -> Bool {
        let target = targetAngle(for: direction)
        let angle = atan2(dy, dx) * 180 / .pi
        return angularDistance(angle, target) <= toleranceDegrees
    }

    private func targetAngle(for direction: ThreeFingerDirection) -> Double {
        switch direction {
        case .right: return 0
        case .down: return 90
        case .left: return 180
        case .up: return -90
        }
    }

    private func angularDistance(_ first: Double, _ second: Double) -> Double {
        let raw = abs(first - second).truncatingRemainder(dividingBy: 360)
        return raw > 180 ? 360 - raw : raw
    }
}
