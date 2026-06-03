import Foundation

extension NormalizedPoint {
    static func centroid(of touches: [TouchPoint]) -> NormalizedPoint? {
        guard !touches.isEmpty else { return nil }
        let sum = touches.reduce((x: 0.0, y: 0.0)) { total, touch in
            (total.x + touch.position.x, total.y + touch.position.y)
        }
        return NormalizedPoint(
            x: sum.x / Double(touches.count),
            y: sum.y / Double(touches.count)
        )
    }

    func distance(to other: NormalizedPoint) -> Double {
        let deltaX = x - other.x
        let deltaY = y - other.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
}
