import Foundation

final class ClickSuppressionTracker {
    private let rule: ClickSuppressionRule
    private var phase: ClickSuppressionPhase = .idle

    init(rule: ClickSuppressionRule) {
        self.rule = rule
    }

    func update(touches: [TouchPoint], timestamp: TimeInterval) -> ClickSuppressionDecision {
        let activeTouches = touches.filter(\.state.isTouchingSurface)
        guard !activeTouches.isEmpty else {
            phase = .idle
            return .none
        }
        guard activeTouches.count == rule.fingerCount,
              let centroid = NormalizedPoint.centroid(of: activeTouches) else {
            phase = .cancellingUntilRelease
            return .clear
        }

        switch phase {
        case .idle:
            var forceProgress = ForcePressProgress()
            forceProgress.update(
                timestamp: timestamp,
                pressure: maximumPressure(in: activeTouches),
                activationThreshold: rule.minimumPressure,
                sustainingThreshold: rule.sustainingPressure,
                clickSatisfied: true
            )
            phase = .possible(
                anchor: centroid,
                forceProgress: forceProgress
            )
        case .possible(let anchor, var forceProgress):
            guard centroid.distance(to: anchor) <= rule.maximumMovement else {
                phase = .cancellingUntilRelease
                return .clear
            }
            forceProgress.update(
                timestamp: timestamp,
                pressure: maximumPressure(in: activeTouches),
                activationThreshold: rule.minimumPressure,
                sustainingThreshold: rule.sustainingPressure,
                clickSatisfied: true
            )
            if forceProgress.isSatisfied(at: timestamp, minimumMilliseconds: rule.minimumForceMilliseconds) {
                phase = .armed(anchor: anchor)
                return .suppress
            }
            phase = .possible(anchor: anchor, forceProgress: forceProgress)
        case .armed(let anchor):
            guard centroid.distance(to: anchor) <= rule.maximumMovement else {
                phase = .cancellingUntilRelease
                return .clear
            }
            return .suppress
        case .cancellingUntilRelease:
            break
        }

        return .none
    }

    private func maximumPressure(in touches: [TouchPoint]) -> Double {
        touches.map(\.pressure).max() ?? 0
    }
}

enum ClickSuppressionDecision: Equatable {
    case none
    case suppress
    case clear
}

private enum ClickSuppressionPhase: Equatable {
    case idle
    case possible(anchor: NormalizedPoint, forceProgress: ForcePressProgress)
    case armed(anchor: NormalizedPoint)
    case cancellingUntilRelease
}
