@testable import GlissPadCore
import XCTest

final class FourFingerBTTTriggerMigrationTests: XCTestCase {
    func testMigrationMapsBTTNamesToFourFingerParameters() throws {
        let cases: [(String, GestureTriggerType, (FourFingerGestureRule) -> Bool)] = [
            ("4 Finger Touch Start", .fourFingerTouch, { $0.touch.event == .touchStart }),
            ("4 Finger Long Touch", .fourFingerTouch, { $0.touch.event == .longTouch }),
            ("4 Finger Tap", .fourFingerTap, { $0.tap.tapCount == 1 }),
            ("4 Finger Double Tap", .fourFingerTap, { $0.tap.tapCount == 2 }),
            ("4 Finger Click", .fourFingerPress, { $0.press.level == .normal }),
            ("4 Finger FORCE Click", .fourFingerPress, { $0.press.level == .force }),
            ("4 Finger Swipe Up", .fourFingerSwipe, { $0.swipe.direction == .up }),
            ("4 Finger Swipe Down", .fourFingerSwipe, { $0.swipe.direction == .down }),
            ("4 Finger Swipe Left", .fourFingerSwipe, { $0.swipe.direction == .left }),
            ("4 Finger Swipe Right", .fourFingerSwipe, { $0.swipe.direction == .right }),
            ("Pinch With Thumb And 3 Fingers", .thumbThreeFingerScale, { $0.scale.direction == .pinchIn }),
            ("Spread With Thumb And 3 Fingers", .thumbThreeFingerScale, { $0.scale.direction == .spreadOut }),
            ("TipTap Left (3 Fingers Fix)", .fourFingerTipTap, { $0.tipTap.tapSide == .left }),
            ("TipTap Right (3 Fingers Fix)", .fourFingerTipTap, { $0.tipTap.tapSide == .right }),
            ("4 Finger Drawing", .fourFingerDrawing, { $0.drawing.template.id == "shape_l" })
        ]

        for (oldName, expectedType, matches) in cases {
            let migrated = try XCTUnwrap(migrateFourFingerBTTTrigger(oldName: oldName), oldName)
            guard case .fourFinger(_, let type, let rule) = migrated else {
                return XCTFail("Expected four finger trigger for \(oldName).")
            }
            XCTAssertEqual(type, expectedType, oldName)
            XCTAssertTrue(matches(rule), oldName)
        }
    }

    func testMigrationReturnsNilForUnknownNames() {
        XCTAssertNil(migrateFourFingerBTTTrigger(oldName: "4 Finger TipSwipe Up"))
    }
}
