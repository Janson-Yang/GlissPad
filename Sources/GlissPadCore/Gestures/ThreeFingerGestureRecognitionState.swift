import Foundation

struct ThreeFingerTrackingState: Equatable {
    var anchors: [Int: NormalizedPoint]
    var startTouches: [TouchPoint]
    var lastTouches: [TouchPoint]
    var samples: [NormalizedPoint]
    var startedAt: TimeInterval
    var clickBaseline: UInt64
    var sawClick: Bool
    var completed = false
    var triggered = false

    init(frame: TouchFrame, touches: [TouchPoint]) {
        anchors = Dictionary(uniqueKeysWithValues: touches.map { ($0.id, $0.position) })
        startTouches = touches
        lastTouches = touches
        samples = NormalizedPoint.centroid(of: touches).map { [$0] } ?? []
        startedAt = frame.timestamp
        clickBaseline = frame.clickGeneration
        sawClick = frame.hasRecentClick
    }

    mutating func appendSample(from touches: [TouchPoint]) {
        guard let centroid = NormalizedPoint.centroid(of: touches) else { return }
        if samples.last?.distance(to: centroid) ?? .infinity >= 0.004 {
            samples.append(centroid)
        }
        lastTouches = touches
    }
}

struct ThreeFingerTipBase: Equatable {
    var anchors: [Int: NormalizedPoint]
    var startedAt: TimeInterval
}

struct ThreeFingerTipState: Equatable {
    var base: ThreeFingerTipBase
    var activeID: Int
    var activeAnchor: NormalizedPoint
    var startedAt: TimeInterval
    var completed = false
    var triggered = false
}

struct ThreeFingerPendingTap: Equatable {
    var count: Int
    var timestamp: TimeInterval
    var anchor: NormalizedPoint
}

enum ThreeFingerRecognitionPhase: Equatable {
    case idle
    case tracking(ThreeFingerTrackingState)
    case tipBase(ThreeFingerTipBase)
    case tip(ThreeFingerTipState)
    case cancellingUntilRelease
}

extension Array where Element == TouchPoint {
    func sortedByHorizontalPosition() -> [TouchPoint] {
        sorted { first, second in
            if first.position.x == second.position.x {
                return first.id < second.id
            }
            return first.position.x < second.position.x
        }
    }

    func averagePairwiseDistance() -> Double {
        guard count > 1 else { return 0 }
        var distances: [Double] = []
        for firstIndex in indices {
            for secondIndex in indices where secondIndex > firstIndex {
                distances.append(self[firstIndex].position.distance(to: self[secondIndex].position))
            }
        }
        return distances.reduce(0, +) / Double(distances.count)
    }

    func maximumPressure() -> Double {
        map(\.pressure).max() ?? 0
    }
}
