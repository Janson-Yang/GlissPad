import Foundation

extension ThreeFingerGestureRecognizer {
    var effectiveTouchMovementTolerance: Double {
        rule.touch.movementTolerance
    }

    var longTouchReleaseResumeWindow: TimeInterval {
        0.30
    }

    func longTouchPressureCancels(_ frame: TouchFrame) -> Bool {
        frame.activeTouches.maximumPressure() >= TrackpadPressureThreshold.click
    }
}
