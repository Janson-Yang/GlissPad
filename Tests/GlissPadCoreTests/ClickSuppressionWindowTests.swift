@testable import GlissPadCore
import Foundation
import XCTest

final class ClickSuppressionWindowTests: XCTestCase {
    func testSuppressionWindowKeepsLatestDeadline() {
        var window = ClickSuppressionWindow()

        window.extend(now: 10.0, duration: 0.55)
        window.extend(now: 10.1, duration: 0.55)

        XCTAssertTrue(window.contains(now: 10.64))
        XCTAssertTrue(window.contains(now: 10.65))
        XCTAssertFalse(window.contains(now: 10.66))
        XCTAssertFalse(window.contains(now: 10.67))
    }

    func testShorterExtensionDoesNotShrinkWindow() {
        var window = ClickSuppressionWindow()

        window.extend(now: 10.0, duration: 1.0)
        window.extend(now: 10.2, duration: 0.1)

        XCTAssertTrue(window.contains(now: 10.99))
        XCTAssertFalse(window.contains(now: 11.01))
    }

    func testSuppressionWindowCanBeCleared() {
        var window = ClickSuppressionWindow()

        window.extend(now: 10.0, duration: 1.0)
        window.clear()

        XCTAssertFalse(window.contains(now: 10.1))
    }

    func testSuppressionTrackerWaitsForStationaryForcePress() {
        let tracker = ClickSuppressionTracker(rule: suppressionRule())

        XCTAssertEqual(tracker.update(touches: threeFingerTouches(pressure: TrackpadPressureThreshold.forceClick), timestamp: 1.0), .none)
        XCTAssertEqual(tracker.update(touches: threeFingerTouches(pressure: TrackpadPressureThreshold.forceClick), timestamp: 1.05), .none)
        XCTAssertEqual(tracker.update(touches: threeFingerTouches(pressure: TrackpadPressureThreshold.forceClick), timestamp: 1.09), .suppress)
    }

    func testSuppressionTrackerClearsWhenTouchesMove() {
        let tracker = ClickSuppressionTracker(rule: suppressionRule())

        XCTAssertEqual(tracker.update(touches: threeFingerTouches(pressure: TrackpadPressureThreshold.forceClick), timestamp: 1.0), .none)
        XCTAssertEqual(
            tracker.update(touches: threeFingerTouches(
                xOffset: 0.12,
                pressure: TrackpadPressureThreshold.forceClick
            ), timestamp: 1.04),
            .clear
        )
        XCTAssertEqual(
            tracker.update(touches: threeFingerTouches(
                xOffset: 0.13,
                pressure: TrackpadPressureThreshold.forceClick
            ), timestamp: 1.09),
            .none
        )
    }

    private func suppressionRule() -> ClickSuppressionRule {
        ClickSuppressionRule(
            fingerCount: 3,
            minimumPressure: TrackpadPressureThreshold.forceClick,
            sustainingPressure: TrackpadPressureThreshold.forceClickSustain,
            minimumForceMilliseconds: 80,
            maximumMovement: 0.045
        )
    }

    private func threeFingerTouches(xOffset: Double = 0, pressure: Double) -> [TouchPoint] {
        [
            touch(id: 1, x: 0.2 + xOffset, y: 0.3, pressure: pressure),
            touch(id: 2, x: 0.3 + xOffset, y: 0.3, pressure: pressure),
            touch(id: 3, x: 0.4 + xOffset, y: 0.3, pressure: pressure)
        ]
    }

    private func touch(id: Int, x: Double, y: Double, pressure: Double) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: y),
            pressure: pressure,
            size: pressure
        )
    }
}
