import Foundation

struct FreeformPathMatcher: Equatable {
    let template: [NormalizedPoint]
    let tolerance: Double
    let sampleCount: Int

    init(template: [NormalizedPoint], tolerance: Double, sampleCount: Int = 32) {
        self.template = template
        self.tolerance = tolerance
        self.sampleCount = sampleCount
    }

    func matches(_ observed: [NormalizedPoint]) -> Bool {
        guard template.count >= 2, observed.count >= 2 else { return false }
        guard pathLength(template) >= 0.05, pathLength(observed) >= 0.05 else { return false }
        let expected = resample(template, count: sampleCount)
        let actual = resample(observed, count: sampleCount)
        guard expected.count == sampleCount, actual.count == sampleCount else { return false }
        return endpointDistance(expected, actual) <= endpointTolerance
            && averageDistance(expected, actual) <= tolerance
            && maximumDistance(expected, actual) <= tolerance * 2.4
    }

    private var endpointTolerance: Double {
        max(tolerance * 1.7, 0.08)
    }

    private func endpointDistance(_ first: [NormalizedPoint], _ second: [NormalizedPoint]) -> Double {
        first[0].distance(to: second[0]) + first[first.count - 1].distance(to: second[second.count - 1])
    }

    private func averageDistance(_ first: [NormalizedPoint], _ second: [NormalizedPoint]) -> Double {
        zip(first, second).map { $0.distance(to: $1) }.reduce(0, +) / Double(first.count)
    }

    private func maximumDistance(_ first: [NormalizedPoint], _ second: [NormalizedPoint]) -> Double {
        zip(first, second).map { $0.distance(to: $1) }.max() ?? .infinity
    }

    private func resample(_ points: [NormalizedPoint], count: Int) -> [NormalizedPoint] {
        guard count > 1, points.count > 1 else { return points }
        let length = pathLength(points)
        guard length > 0 else { return points }
        return (0..<count).map { index in
            point(at: length * Double(index) / Double(count - 1), in: points)
        }
    }

    private func point(at distance: Double, in points: [NormalizedPoint]) -> NormalizedPoint {
        var traversed = 0.0
        for segmentIndex in 1..<points.count {
            let start = points[segmentIndex - 1]
            let end = points[segmentIndex]
            let segmentLength = start.distance(to: end)
            guard segmentLength > 0 else { continue }
            if traversed + segmentLength >= distance {
                return interpolate(start, end, fraction: (distance - traversed) / segmentLength)
            }
            traversed += segmentLength
        }
        return points[points.count - 1]
    }

    private func interpolate(_ start: NormalizedPoint, _ end: NormalizedPoint, fraction: Double) -> NormalizedPoint {
        NormalizedPoint(
            x: start.x + (end.x - start.x) * fraction,
            y: start.y + (end.y - start.y) * fraction
        )
    }

    private func pathLength(_ points: [NormalizedPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        return zip(points, points.dropFirst()).map { $0.distance(to: $1) }.reduce(0, +)
    }
}
