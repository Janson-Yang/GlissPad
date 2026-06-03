import Foundation

final class ShapeGestureRecognizer {
    private let id: String
    private let rule: ShapeGestureRule
    private let kind: RecognizedGesture.Kind
    private var samples: [NormalizedPoint] = []
    private var lastTriggeredAt: TimeInterval?

    init(id: String, rule: ShapeGestureRule, kind: RecognizedGesture.Kind) {
        self.id = id
        self.rule = rule
        self.kind = kind
    }

    func process(_ frame: TouchFrame) -> RecognizedGesture? {
        guard rule.isEnabled else {
            samples.removeAll()
            return nil
        }
        let activeTouches = frame.activeTouches
        guard activeTouches.count == 1 else {
            return finishIfReleased(frame: frame, activeTouches: activeTouches)
        }
        appendSample(activeTouches[0].position)
        return nil
    }

    private func appendSample(_ point: NormalizedPoint) {
        guard samples.last?.distance(to: point) != 0 else { return }
        samples.append(point)
        if samples.count > 128 {
            samples.removeFirst(samples.count - 128)
        }
    }

    private func finishIfReleased(frame: TouchFrame, activeTouches: [TouchPoint]) -> RecognizedGesture? {
        defer { samples.removeAll() }
        guard activeTouches.isEmpty,
              canTrigger(at: frame.timestamp),
              ShapePathEvaluator(rule: rule).matches(samples) else { return nil }
        lastTriggeredAt = frame.timestamp
        return RecognizedGesture(id: id, kind: kind, name: rule.name, actions: rule.actions, frame: frame)
    }

    private func canTrigger(at timestamp: TimeInterval) -> Bool {
        guard let lastTriggeredAt else { return true }
        return timestamp - lastTriggeredAt >= TimeInterval(rule.cooldownMilliseconds) / 1000
    }
}

private struct ShapePathEvaluator {
    let rule: ShapeGestureRule

    func matches(_ points: [NormalizedPoint]) -> Bool {
        let points = deduplicated(points)
        guard points.count >= 6, let bounds = ShapeBounds(points: points) else { return false }
        guard bounds.minimumDimension >= rule.minimumSize else { return false }
        guard closed(points, bounds: bounds) else { return false }
        let simplified = PolygonPathSimplifier(epsilon: bounds.minimumDimension * rule.cornerTolerance)
            .simplify(closedPath(points))
        let vertices = openVertices(simplified, bounds: bounds)
        guard corners(in: vertices) == rule.shape.cornerCount else { return false }
        return rule.shape == .triangle || bounds.aspectRatio <= 2.0
    }

    private func deduplicated(_ points: [NormalizedPoint]) -> [NormalizedPoint] {
        points.reduce(into: []) { result, point in
            if result.last?.distance(to: point) != 0 { result.append(point) }
        }
    }

    private func closed(_ points: [NormalizedPoint], bounds: ShapeBounds) -> Bool {
        guard let first = points.first, let last = points.last else { return false }
        return first.distance(to: last) <= max(bounds.minimumDimension * 0.3, 0.06)
    }

    private func closedPath(_ points: [NormalizedPoint]) -> [NormalizedPoint] {
        guard let first = points.first, let last = points.last, first.distance(to: last) > 0 else { return points }
        return points + [first]
    }

    private func openVertices(_ points: [NormalizedPoint], bounds: ShapeBounds) -> [NormalizedPoint] {
        guard points.count > 1, let first = points.first, let last = points.last else { return points }
        let closureLimit = max(bounds.minimumDimension * 0.35, 0.04)
        return first.distance(to: last) <= closureLimit ? Array(points.dropLast()) : points
    }

    private func corners(in vertices: [NormalizedPoint]) -> Int {
        guard vertices.count >= 3 else { return 0 }
        return vertices.indices.reduce(0) { count, index in
            count + (turnAngle(at: index, in: vertices) >= 0.75 ? 1 : 0)
        }
    }

    private func turnAngle(at index: Int, in vertices: [NormalizedPoint]) -> Double {
        let previous = vertices[(index + vertices.count - 1) % vertices.count]
        let current = vertices[index]
        let next = vertices[(index + 1) % vertices.count]
        return angleBetween(vector(from: previous, to: current), vector(from: current, to: next))
    }

    private func vector(from start: NormalizedPoint, to end: NormalizedPoint) -> ShapeVector {
        ShapeVector(x: end.x - start.x, y: end.y - start.y)
    }

    private func angleBetween(_ first: ShapeVector, _ second: ShapeVector) -> Double {
        let lengths = first.length * second.length
        guard lengths > 0 else { return 0 }
        let cosine = max(-1, min(1, first.dot(second) / lengths))
        return acos(cosine)
    }
}

private struct PolygonPathSimplifier {
    let epsilon: Double

    func simplify(_ points: [NormalizedPoint]) -> [NormalizedPoint] {
        guard points.count > 2 else { return points }
        return simplify(points, start: 0, end: points.count - 1)
    }

    private func simplify(_ points: [NormalizedPoint], start: Int, end: Int) -> [NormalizedPoint] {
        let farthest = farthestPoint(in: points, start: start, end: end)
        guard farthest.distance > epsilon, farthest.index > start, farthest.index < end else {
            return [points[start], points[end]]
        }
        let left = simplify(points, start: start, end: farthest.index)
        let right = simplify(points, start: farthest.index, end: end)
        return Array(left.dropLast()) + right
    }

    private func farthestPoint(in points: [NormalizedPoint], start: Int, end: Int) -> (index: Int, distance: Double) {
        guard end - start > 1 else { return (start, 0) }
        return ((start + 1)..<end).reduce((index: start, distance: 0.0)) { best, index in
            let distance = lineDistance(points[index], from: points[start], to: points[end])
            return distance > best.distance ? (index, distance) : best
        }
    }

    private func lineDistance(_ point: NormalizedPoint, from start: NormalizedPoint, to end: NormalizedPoint) -> Double {
        let segment = ShapeVector(x: end.x - start.x, y: end.y - start.y)
        guard segment.length > 0 else { return point.distance(to: start) }
        let numerator = abs(segment.y * point.x - segment.x * point.y + end.x * start.y - end.y * start.x)
        return numerator / segment.length
    }
}

private struct ShapeBounds {
    let width: Double
    let height: Double

    init?(points: [NormalizedPoint]) {
        guard let first = points.first else { return nil }
        let bounds = points.reduce((minX: first.x, maxX: first.x, minY: first.y, maxY: first.y)) { result, point in
            (
                minX: min(result.minX, point.x),
                maxX: max(result.maxX, point.x),
                minY: min(result.minY, point.y),
                maxY: max(result.maxY, point.y)
            )
        }
        width = bounds.maxX - bounds.minX
        height = bounds.maxY - bounds.minY
    }

    var minimumDimension: Double { min(width, height) }
    var aspectRatio: Double { max(width, height) / max(minimumDimension, 0.000_1) }
}

private struct ShapeVector {
    let x: Double
    let y: Double

    var length: Double { sqrt(x * x + y * y) }

    func dot(_ other: ShapeVector) -> Double {
        x * other.x + y * other.y
    }
}
