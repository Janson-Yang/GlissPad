import Foundation

public enum TrackpadPressureThreshold {
    public static let touch = 0.7
    public static let click = 1.0
    public static let clickSustain = 0.8
    public static let forceClick = 1.3
    public static let forceClickSustain = 1.0

    public static func value(for kind: CornerClickKind) -> Double {
        switch kind {
        case .tap:
            return touch
        case .click:
            return click
        case .forceClick:
            return forceClick
        }
    }

    public static func value(for kind: HoldPressKind) -> Double {
        switch kind {
        case .touch:
            return touch
        case .click:
            return click
        case .forceClick:
            return forceClick
        }
    }

    public static func value(for kind: OneFingerPressKind) -> Double {
        switch kind {
        case .click:
            return click
        case .forceClick:
            return forceClick
        }
    }

    public static func sustain(for kind: CornerClickKind) -> Double {
        switch kind {
        case .tap:
            return touch
        case .click:
            return clickSustain
        case .forceClick:
            return forceClickSustain
        }
    }

    public static func sustain(for kind: HoldPressKind) -> Double {
        switch kind {
        case .touch:
            return touch
        case .click:
            return clickSustain
        case .forceClick:
            return forceClickSustain
        }
    }

    public static func sustain(for kind: OneFingerPressKind) -> Double {
        switch kind {
        case .click:
            return clickSustain
        case .forceClick:
            return forceClickSustain
        }
    }
}
