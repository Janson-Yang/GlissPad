import Foundation

struct ThreeFingerTrackingState: Equatable {
    var anchors: [Int: NormalizedPoint]
    var centroidAnchor: NormalizedPoint?
    var startTouches: [TouchPoint]
    var lastTouches: [TouchPoint]
    var samples: [NormalizedPoint]
    var startedAt: TimeInterval
    var clickBaseline: UInt64
    var sawClick: Bool
    var maximumObservedPressure: Double
    var completed = false
    var triggered = false
    var lastRepeatAt: TimeInterval?
    var releaseStartedAt: TimeInterval?

    init(frame: TouchFrame, touches: [TouchPoint], collection: ThreeFingerCollectionState? = nil) {
        let centroid = NormalizedPoint.centroid(of: touches)
        anchors = Dictionary(uniqueKeysWithValues: touches.map { ($0.id, $0.position) })
        centroidAnchor = centroid
        startTouches = touches
        lastTouches = touches
        samples = centroid.map { [$0] } ?? []
        startedAt = frame.timestamp
        clickBaseline = collection?.clickBaseline ?? frame.clickGeneration
        sawClick = (collection?.sawClick ?? false) || frame.hasRecentClick
        maximumObservedPressure = max(collection?.maximumObservedPressure ?? 0, touches.maximumPressure())
    }

    mutating func appendSample(from touches: [TouchPoint]) {
        guard let centroid = NormalizedPoint.centroid(of: touches) else { return }
        if samples.last?.distance(to: centroid) ?? .infinity >= 0.004 {
            samples.append(centroid)
        }
        lastTouches = touches
        maximumObservedPressure = max(maximumObservedPressure, touches.maximumPressure())
    }
}

struct ThreeFingerCollectionState: Equatable {
    var startedAt: TimeInterval
    var threeFingerStartedAt: TimeInterval?
    var threeFingerFrame: TouchFrame?
    var threeFingerTouches: [TouchPoint]?
    var clickBaseline: UInt64
    var sawClick: Bool
    var maximumObservedPressure: Double

    init(
        startedAt: TimeInterval,
        threeFingerStartedAt: TimeInterval? = nil,
        threeFingerFrame: TouchFrame? = nil,
        threeFingerTouches: [TouchPoint]? = nil,
        clickBaseline: UInt64 = 0,
        sawClick: Bool = false,
        maximumObservedPressure: Double = 0
    ) {
        self.startedAt = startedAt
        self.threeFingerStartedAt = threeFingerStartedAt
        self.threeFingerFrame = threeFingerFrame
        self.threeFingerTouches = threeFingerTouches
        self.clickBaseline = clickBaseline
        self.sawClick = sawClick
        self.maximumObservedPressure = maximumObservedPressure
    }

    init(frame: TouchFrame) {
        self.init(
            startedAt: frame.timestamp,
            clickBaseline: frame.clickGeneration,
            sawClick: false,
            maximumObservedPressure: 0
        )
    }

    mutating func record(frame: TouchFrame, active: [TouchPoint]) {
        guard active.count == 3 else { return }
        sawClick = sawClick || frame.hasRecentClick || frame.clickGeneration > clickBaseline
        maximumObservedPressure = max(maximumObservedPressure, active.maximumPressure())
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

struct ThreeFingerTipCandidateState: Equatable {
    var anchors: [Int: NormalizedPoint]
    var startedAt: TimeInterval
}

struct ThreeFingerPendingTap: Equatable {
    var count: Int
    var timestamp: TimeInterval
    var anchor: NormalizedPoint
}

enum ThreeFingerRecognitionPhase: Equatable {
    case idle
    case collecting(ThreeFingerCollectionState)
    case tracking(ThreeFingerTrackingState)
    case releasing(ThreeFingerTrackingState)
    case tipBase(ThreeFingerTipBase)
    case tipCandidate(ThreeFingerTipCandidateState)
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
