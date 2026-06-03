import Foundation

struct RelativePathMatcher: Equatable {
    let template: [NormalizedPoint]
    let tolerance: Double
    let sampleCount: Int

    init(template: [NormalizedPoint], tolerance: Double, sampleCount: Int = 32) {
        self.template = template
        self.tolerance = tolerance
        self.sampleCount = sampleCount
    }

    func matches(_ observed: [NormalizedPoint]) -> Bool {
        guard let expected = Self.normalized(template),
              let actual = Self.normalized(observed) else {
            return false
        }
        return FreeformPathMatcher(
            template: expected,
            tolerance: tolerance,
            sampleCount: sampleCount
        ).matches(actual)
    }

    private static func normalized(_ points: [NormalizedPoint]) -> [NormalizedPoint]? {
        guard points.count >= 2 else { return nil }
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0
        let scale = max(maxX - minX, maxY - minY)
        guard scale >= 0.03 else { return nil }
        return points.map {
            NormalizedPoint(x: ($0.x - minX) / scale, y: ($0.y - minY) / scale)
        }
    }
}
