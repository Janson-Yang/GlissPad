@testable import GlissPadCore
import XCTest

final class LatencyActionTests: XCTestCase {
    func testValidationAcceptsBoundaryDurations() throws {
        try LatencyAction(
            name: "Shortest",
            durationMilliseconds: LatencyAction.minimumDurationMilliseconds
        ).validate(name: "action")
        try LatencyAction(
            name: "Longest",
            durationMilliseconds: LatencyAction.maximumDurationMilliseconds
        ).validate(name: "action")
    }

    func testValidationRejectsOutOfRangeDurations() {
        XCTAssertThrowsError(try LatencyAction(
            name: "Zero",
            durationMilliseconds: LatencyAction.minimumDurationMilliseconds - 1
        ).validate(name: "action"))
        XCTAssertThrowsError(try LatencyAction(
            name: "Too Long",
            durationMilliseconds: LatencyAction.maximumDurationMilliseconds + 1
        ).validate(name: "action"))
    }
}
