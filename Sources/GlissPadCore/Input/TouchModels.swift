import Foundation

public struct TouchFrame: Equatable, Sendable {
    let touches: [TouchPoint]
    let timestamp: TimeInterval
    let frameNumber: Int
    let clickGeneration: UInt64
    let hasRecentClick: Bool

    var activeTouches: [TouchPoint] {
        touches.filter(\.state.isTouchingSurface)
    }

    init(
        touches: [TouchPoint],
        timestamp: TimeInterval,
        frameNumber: Int,
        clickGeneration: UInt64 = 0,
        hasRecentClick: Bool = false
    ) {
        self.touches = touches
        self.timestamp = timestamp
        self.frameNumber = frameNumber
        self.clickGeneration = clickGeneration
        self.hasRecentClick = hasRecentClick
    }
}

public struct TouchPoint: Equatable, Sendable {
    let id: Int
    let state: TouchState
    let position: NormalizedPoint
    let pressure: Double
    let size: Double
}

public struct NormalizedPoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public enum TouchState: Int32, Equatable, Sendable {
    case notTracking = 0
    case startInRange = 1
    case hoverInRange = 2
    case makeTouch = 3
    case touching = 4
    case breakTouch = 5
    case lingerInRange = 6
    case outOfRange = 7
    case unknown = -1

    public init(rawValue: Int32) {
        switch rawValue {
        case 0: self = .notTracking
        case 1: self = .startInRange
        case 2: self = .hoverInRange
        case 3: self = .makeTouch
        case 4: self = .touching
        case 5: self = .breakTouch
        case 6: self = .lingerInRange
        case 7: self = .outOfRange
        default: self = .unknown
        }
    }

    var isTouchingSurface: Bool {
        self == .makeTouch || self == .touching
    }
}
