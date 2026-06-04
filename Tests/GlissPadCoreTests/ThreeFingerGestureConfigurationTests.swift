@testable import GlissPadCore
import XCTest

final class ThreeFingerGestureConfigurationTests: XCTestCase {
    func testThreeFingerDefaultTriggersValidateAndRoundTrip() throws {
        for type in threeFingerTypes {
            let trigger = type.defaultTrigger(id: type.defaultID, ordinal: 1)

            XCTAssertNoThrow(try trigger.validate(name: type.rawValue))
            XCTAssertEqual(trigger.type, type)

            let data = try JSONEncoder().encode(trigger)
            let decoded = try JSONDecoder().decode(GestureRule.self, from: data)
            XCTAssertEqual(decoded, trigger)
        }
    }

    func testThreeFingerTypesAreExposedAsFamilies() {
        XCTAssertEqual(threeFingerTypes.map(\.displayName), [
            "Three Finger Touch",
            "Three Finger Tap",
            "Three Finger Press",
            "Three Finger Swipe",
            "Three Finger TipTap",
            "Three Finger TipSwipe",
            "Thumb + Two Fingers Pinch / Spread",
            "Three Finger Drawing"
        ])
        XCTAssertTrue(threeFingerTypes.allSatisfy(\.isThreeFingerGestureFamily))
    }

    private var threeFingerTypes: [GestureTriggerType] {
        [
            .threeFingerTouch,
            .threeFingerTap,
            .threeFingerPress,
            .threeFingerSwipe,
            .threeFingerTipTap,
            .threeFingerTipSwipe,
            .thumbTwoFingerScale,
            .threeFingerDrawing
        ]
    }
}

