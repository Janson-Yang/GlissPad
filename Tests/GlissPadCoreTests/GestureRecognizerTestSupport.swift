@testable import GlissPadCore
import Foundation

private let legacyDefaultTriggerTypes: [GestureTriggerType] = [
    .threeFingerForcePress,
    .upperLeftForcePress,
    .leftEdgeTwoFingerSwipe,
    .twoFingerHold,
    .upperRightForcePress
]

extension GestureRecognizerTests {
    func legacyDefaultRecognizer() -> GestureRecognizer {
        GestureRecognizer(configuration: legacyDefaultConfiguration())
    }

    func legacyDefaultConfiguration() -> GestureConfiguration {
        GestureConfiguration(triggers: legacyDefaultTriggerTypes.map {
            $0.defaultTrigger(id: $0.defaultID, ordinal: 1)
        })
    }

    func armAndReleaseThreeFingerPress(_ recognizer: GestureRecognizer, start: TimeInterval) {
        let forcePressure = TrackpadPressureThreshold.forceClick
        _ = recognizer.process(threeFingerFrame(timestamp: start, pressure: forcePressure, clickGeneration: 10))
        _ = recognizer.process(threeFingerFrame(timestamp: start + 0.09, pressure: forcePressure, clickGeneration: 11))
        _ = recognizer.process(frame(touches: [], timestamp: start + 0.12, clickGeneration: 11))
    }

    func threeFingerFrame(
        timestamp: TimeInterval,
        pressure: Double,
        clickGeneration: UInt64 = 0,
        hasRecentClick: Bool = false
    ) -> TouchFrame {
        frame(touches: [
            touch(id: 1, x: 0.2, y: 0.3, pressure: pressure),
            touch(id: 2, x: 0.3, y: 0.3, pressure: pressure),
            touch(id: 3, x: 0.4, y: 0.3, pressure: pressure)
        ], timestamp: timestamp, clickGeneration: clickGeneration, hasRecentClick: hasRecentClick)
    }

    func twoFingerFrame(timestamp: TimeInterval, x: Double, y: Double) -> TouchFrame {
        frame(touches: [
            touch(id: 1, x: x - 0.02, y: y, pressure: TrackpadPressureThreshold.touch),
            touch(id: 2, x: x + 0.02, y: y, pressure: TrackpadPressureThreshold.touch)
        ], timestamp: timestamp)
    }

    func frame(
        touches: [TouchPoint],
        timestamp: TimeInterval,
        clickGeneration: UInt64 = 0,
        hasRecentClick: Bool = false
    ) -> TouchFrame {
        TouchFrame(
            touches: touches,
            timestamp: timestamp,
            frameNumber: Int(timestamp * 100),
            clickGeneration: clickGeneration,
            hasRecentClick: hasRecentClick
        )
    }

    func touch(id: Int, x: Double, y: Double, pressure: Double) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: y),
            pressure: pressure,
            size: pressure
        )
    }
}
