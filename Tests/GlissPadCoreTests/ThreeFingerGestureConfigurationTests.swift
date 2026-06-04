@testable import GlissPadCore
import Foundation
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

    func testTipFingerReferenceDefaultsToTrackpadPosition() {
        XCTAssertEqual(ThreeFingerTipTapOptions().tapPosition, .auto)
        XCTAssertEqual(ThreeFingerTipTapOptions().positionReference, .trackpad)
        XCTAssertEqual(ThreeFingerTipSwipeOptions().activeFingerReference, .trackpad)
    }

    func testLegacyTouchOrderReferencesStillDecode() throws {
        let tipTap = try JSONDecoder().decode(ThreeFingerTipTapOptions.self, from: Data(Self.tipTapTouchOrderJSON.utf8))
        let tipSwipe = try JSONDecoder().decode(ThreeFingerTipSwipeOptions.self, from: Data(Self.tipSwipeTouchOrderJSON.utf8))

        XCTAssertEqual(tipTap.positionReference, .touchOrder)
        XCTAssertEqual(tipSwipe.activeFingerReference, .touchOrder)
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

    private static let tipTapTouchOrderJSON = """
    {
      "fixedFingers": 2,
      "tapPosition": "middle",
      "positionReference": "touchOrder",
      "tapCount": 1,
      "maximumTapMilliseconds": 180,
      "maximumActiveFingerMovement": 0.05,
      "maximumFixedFingerMovement": 0.03,
      "minimumFixedFingerHoldMilliseconds": 50
    }
    """

    private static let tipSwipeTouchOrderJSON = """
    {
      "fixedFingers": 2,
      "activeFinger": "middle",
      "activeFingerReference": "touchOrder",
      "direction": "up",
      "minimumTravel": 0.12,
      "minimumVelocity": 0.75,
      "directionToleranceDegrees": 35,
      "maximumFixedFingerMovement": 0.04,
      "minimumFixedFingerHoldMilliseconds": 50,
      "triggerTiming": "thresholdReached"
    }
    """
}
