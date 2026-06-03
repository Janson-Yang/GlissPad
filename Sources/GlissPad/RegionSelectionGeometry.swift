import AppKit
import GlissPadCore

struct DragState {
    let target: DragTarget
    let startPoint: NSPoint
    let startRegion: NormalizedRegion
}

enum DragTarget {
    case none
    case body
    case corner(Corner)
}

enum Corner: CaseIterable {
    case minXMinY
    case maxXMinY
    case minXMaxY
    case maxXMaxY
}

struct RegionPoint {
    let x: Double
    let y: Double
}

func clamp(_ value: Double, min: Double, max: Double) -> Double {
    Swift.min(Swift.max(value, min), max)
}

extension NSPoint {
    func distance(to other: NSPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
