@testable import GlissPadCore
import Foundation
import XCTest

extension ThreeFingerGestureRecognizerTests {
    func recognizer(_ type: GestureTriggerType, rule: ThreeFingerGestureRule? = nil) -> GestureRecognizer {
        GestureRecognizer(configuration: GestureConfiguration(triggers: [trigger(type, rule: rule)]))
    }

    func trigger(_ type: GestureTriggerType, rule: ThreeFingerGestureRule? = nil) -> GestureRule {
        .threeFinger(id: type.rawValue, type: type, rule: rule ?? threeFingerRule(type))
    }

    func threeFingerRule(_ type: GestureTriggerType) -> ThreeFingerGestureRule {
        guard case .threeFinger(_, _, let rule) = type.defaultTrigger(id: type.rawValue, ordinal: 1) else {
            XCTFail("Expected three finger default")
            return ThreeFingerGestureRule(name: "broken", isEnabled: false, cooldownMilliseconds: 650, actions: [])
        }
        return rule
    }

    func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    func touches(at x: Double, _ y: Double) -> [TouchPoint] {
        [
            touch(id: 1, x: x - 0.04, y: y),
            touch(id: 2, x: x, y: y),
            touch(id: 3, x: x + 0.04, y: y)
        ]
    }

    func touch(
        id: Int,
        x: Double,
        y: Double,
        pressure: Double = 0.2,
        size: Double = 0.2
    ) -> TouchPoint {
        TouchPoint(id: id, state: .touching, position: NormalizedPoint(x: x, y: y), pressure: pressure, size: size)
    }

    func biasedPressures() -> [TouchPoint] {
        [
            touch(id: 1, x: 0.2, y: 0.5, pressure: 0.2),
            touch(id: 2, x: 0.4, y: 0.5, pressure: 0.2),
            touch(id: 3, x: 0.6, y: 0.5, pressure: 1.5)
        ]
    }

    func baseTouches() -> [TouchPoint] {
        [touch(id: 1, x: 0.3, y: 0.5), touch(id: 2, x: 0.5, y: 0.5)]
    }

    func spreadStart() -> [TouchPoint] {
        [touch(id: 1, x: 0.2, y: 0.5), touch(id: 2, x: 0.25, y: 0.5), touch(id: 3, x: 0.3, y: 0.5)]
    }

    func spreadEnd() -> [TouchPoint] {
        [touch(id: 1, x: 0.3, y: 0.5), touch(id: 2, x: 0.6, y: 0.5), touch(id: 3, x: 0.9, y: 0.5)]
    }

    func thumbScaleStart() -> [TouchPoint] {
        [
            touch(id: 1, x: 0.2, y: 0.5, size: 0.6),
            touch(id: 2, x: 0.5, y: 0.45),
            touch(id: 3, x: 0.55, y: 0.55)
        ]
    }

    func thumbScaleEnd() -> [TouchPoint] {
        [
            touch(id: 1, x: 0.1, y: 0.5, size: 0.6),
            touch(id: 2, x: 0.75, y: 0.45),
            touch(id: 3, x: 0.85, y: 0.55)
        ]
    }
}
