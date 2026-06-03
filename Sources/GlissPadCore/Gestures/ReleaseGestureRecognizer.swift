import Foundation

final class ReleaseGestureRecognizer {
    private struct PendingRelease {
        var originalFingerCount: Int
        var lastFingerLeftAt: TimeInterval
    }

    private let id: String
    private let rule: ReleaseGestureRule
    private let kind: RecognizedGesture.Kind
    private var previousActiveFingerCount = 0
    private var pendingRelease: PendingRelease?
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: ReleaseGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            resetTracking()
            return nil
        }
        let activeFingerCount = frame.activeTouches.count
        expirePendingRelease(at: frame.timestamp)
        let gesture = recognizeReleaseIfNeeded(activeFingerCount: activeFingerCount, frame: frame)
        if activeFingerCount > 0 {
            updatePendingRelease(activeFingerCount: activeFingerCount, timestamp: frame.timestamp)
        }
        previousActiveFingerCount = activeFingerCount
        return gesture
    }

    private func recognizeReleaseIfNeeded(activeFingerCount: Int, frame: TouchFrame) -> RecognizedGesture? {
        guard activeFingerCount == 0, previousActiveFingerCount > 0 else { return nil }
        defer { pendingRelease = nil }
        let releasedFingerCount = pendingRelease?.originalFingerCount ?? previousActiveFingerCount
        guard rule.previousFingerCount.matches(releasedFingerCount),
              canTrigger(at: frame.timestamp) else { return nil }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func updatePendingRelease(activeFingerCount: Int, timestamp: TimeInterval) {
        guard previousActiveFingerCount > 0 else { return }
        guard activeFingerCount < previousActiveFingerCount else {
            if activeFingerCount > previousActiveFingerCount { pendingRelease = nil }
            return
        }
        let originalFingerCount = max(pendingRelease?.originalFingerCount ?? 0, previousActiveFingerCount)
        pendingRelease = PendingRelease(originalFingerCount: originalFingerCount, lastFingerLeftAt: timestamp)
    }

    private func expirePendingRelease(at timestamp: TimeInterval) {
        guard let pendingRelease else { return }
        if timestamp - pendingRelease.lastFingerLeftAt > releaseToleranceSeconds {
            self.pendingRelease = nil
        }
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        let cooldown = TimeInterval(rule.cooldownMilliseconds) / 1000
        return timestamp - lastTriggeredAt >= cooldown
    }

    private var releaseToleranceSeconds: TimeInterval {
        TimeInterval(rule.releaseToleranceMilliseconds) / 1000
    }

    private func resetTracking() {
        previousActiveFingerCount = 0
        pendingRelease = nil
    }
}
