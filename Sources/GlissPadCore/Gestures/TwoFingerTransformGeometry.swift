import Foundation

struct TwoFingerTransformGeometry: Equatable {
    var firstID: Int
    var secondID: Int
    var firstPosition: NormalizedPoint
    var secondPosition: NormalizedPoint
    var centroid: NormalizedPoint
    var distance: Double
    var angleDegrees: Double

    init?(touches: [TouchPoint]) {
        guard touches.count == 2, let centroid = NormalizedPoint.centroid(of: touches) else { return nil }
        let orderedTouches = touches.sorted { $0.id < $1.id }
        let first = orderedTouches[0].position
        let second = orderedTouches[1].position
        let distance = first.distance(to: second)
        guard distance > 0.001 else { return nil }
        firstID = orderedTouches[0].id
        secondID = orderedTouches[1].id
        firstPosition = first
        secondPosition = second
        self.centroid = centroid
        self.distance = distance
        angleDegrees = atan2(second.y - first.y, second.x - first.x) * 180 / .pi
    }

    func hasSameTouchIDs(as other: TwoFingerTransformGeometry) -> Bool {
        firstID == other.firstID && secondID == other.secondID
    }

    func matchesRotation(
        to current: TwoFingerTransformGeometry,
        minimumDegrees: Double,
        direction: TwoFingerRotationDirection
    ) -> Bool {
        let delta = rotationDelta(to: current)
        guard hasSameTouchIDs(as: current),
              abs(delta) >= minimumDegrees,
              direction.matches(delta),
              scaleChange(to: current) <= 0.35 else {
            return false
        }
        return isBalancedRotation(to: current, direction: direction, minimumDegrees: minimumDegrees)
            || isPivotRotation(to: current, direction: direction, minimumDegrees: minimumDegrees)
    }

    private func rotationDelta(to current: TwoFingerTransformGeometry) -> Double {
        var delta = current.angleDegrees - angleDegrees
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        return delta
    }

    private var maximumBalancedCentroidDrift: Double {
        min(max(0.035, distance * 0.35), 0.09)
    }

    private var maximumPivotCentroidDrift: Double {
        min(max(0.055, distance * 0.65), 0.14)
    }

    private func isBalancedRotation(
        to current: TwoFingerTransformGeometry,
        direction: TwoFingerRotationDirection,
        minimumDegrees: Double
    ) -> Bool {
        guard centroid.distance(to: current.centroid) <= maximumBalancedCentroidDrift else { return false }
        let requiredTravel = max(0.006, distance * sin(minimumDegrees * .pi / 360) * 0.55)
        return [firstID, secondID].allSatisfy { id in
            guard let travel = tangentialTravel(to: current, id: id) else { return false }
            return travel * direction.sign >= requiredTravel
        }
    }

    private func isPivotRotation(
        to current: TwoFingerTransformGeometry,
        direction: TwoFingerRotationDirection,
        minimumDegrees: Double
    ) -> Bool {
        guard centroid.distance(to: current.centroid) <= maximumPivotCentroidDrift else { return false }
        let requiredTravel = max(0.012, distance * sin(minimumDegrees * .pi / 180) * 0.45)
        let stationaryTolerance = max(0.012, distance * 0.12)
        return pivotPairIDs.contains { stationaryID, movingID in
            guard let movingTravel = tangentialTravel(to: current, id: movingID) else { return false }
            return movement(to: current, id: stationaryID) <= stationaryTolerance
                && movingTravel * direction.sign >= requiredTravel
        }
    }

    private var pivotPairIDs: [(stationary: Int, moving: Int)] {
        [(firstID, secondID), (secondID, firstID)]
    }

    private func tangentialTravel(to current: TwoFingerTransformGeometry, id: Int) -> Double? {
        guard let start = position(for: id), let end = current.position(for: id) else { return nil }
        let radialX = start.x - centroid.x
        let radialY = start.y - centroid.y
        let radius = sqrt(radialX * radialX + radialY * radialY)
        guard radius > 0.001 else { return nil }
        let tangentX = -radialY / radius
        let tangentY = radialX / radius
        return (end.x - start.x) * tangentX + (end.y - start.y) * tangentY
    }

    private func movement(to current: TwoFingerTransformGeometry, id: Int) -> Double {
        guard let start = position(for: id), let end = current.position(for: id) else { return .infinity }
        return start.distance(to: end)
    }

    private func position(for id: Int) -> NormalizedPoint? {
        if id == firstID { return firstPosition }
        if id == secondID { return secondPosition }
        return nil
    }

    private func scaleChange(to current: TwoFingerTransformGeometry) -> Double {
        abs(current.distance / distance - 1)
    }
}

struct TwoFingerTransformTrackingState: Equatable {
    var start: TwoFingerTransformGeometry
    var completed = false
}

enum TwoFingerRotationDirection {
    case left
    case right

    var sign: Double {
        switch self {
        case .left: return 1
        case .right: return -1
        }
    }

    func matches(_ delta: Double) -> Bool {
        delta * sign > 0
    }
}
