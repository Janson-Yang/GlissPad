@testable import GlissPadCore
import XCTest

final class FiveAndMoreFingerTriggerMigrationTests: XCTestCase {
    func testMigrationMapsFlattenedNamesToSevenTriggerFamilies() throws {
        let cases: [(String, GestureTriggerType, (FiveAndMoreFingerGestureRule) -> Bool)] = [
            ("5 Finger Touch Start", .fiveFingerTouch, { $0.touch.event == .touchStart }),
            ("5 Finger Long Touch", .fiveFingerTouch, { $0.touch.event == .longTouch }),
            ("5 Finger Touch", .fiveFingerTouch, { $0.touch.event == .stableTouch }),
            ("5 Finger Tap", .fiveFingerTap, { $0.tap.tapCount == 1 }),
            ("5 Finger Click", .fiveFingerPress, { $0.press.level == .normal }),
            ("5 Finger FORCE Click", .fiveFingerPress, { $0.press.level == .force }),
            ("Pinch With Thumb And 4 Fingers", .thumbFourFingerScale, { $0.scale.direction == .pinchIn }),
            ("Spread With Thumb And 4 Fingers", .thumbFourFingerScale, { $0.scale.direction == .spreadOut }),
            ("5 Finger Swipe Up", .fiveFingerSwipe, { $0.swipe.direction == .up }),
            ("5 Finger Swipe Down", .fiveFingerSwipe, { $0.swipe.direction == .down }),
            ("5 Finger Swipe Left", .fiveFingerSwipe, { $0.swipe.direction == .left }),
            ("5 Finger Swipe Right", .fiveFingerSwipe, { $0.swipe.direction == .right }),
            ("5 Finger Drawing", .fiveFingerDrawing, { $0.drawing.template.id == "shape_l" }),
            ("11 Finger Tap / Whole Hand", .wholeHandTap, { $0.wholeHandTap.nominalContactCount == 11 })
        ]

        for (oldName, expectedType, matches) in cases {
            let migrated = try XCTUnwrap(migrateFiveAndMoreFingerTrigger(oldName: oldName), oldName)
            guard case .fiveAndMoreFinger(_, let type, let rule) = migrated else {
                return XCTFail("Expected five and more finger trigger for \(oldName).")
            }
            XCTAssertEqual(type, expectedType, oldName)
            XCTAssertTrue(matches(rule), oldName)
        }
    }

    func testMigrationReturnsNilForUnknownNames() {
        XCTAssertNil(migrateFiveAndMoreFingerTrigger(oldName: "5 Finger TipSwipe Up"))
    }
}
