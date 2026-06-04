@testable import GlissPadCore
import Foundation
import XCTest

final class TwoFingerTipTapActiveFingerTests: XCTestCase {
    func testAutoAllowsEitherTipFinger() {
        XCTAssertEqual(tipTapKinds(baseX: 0.65, tipX: 0.35, activeFinger: .auto), [.tipTap])
        XCTAssertEqual(tipTapKinds(baseX: 0.35, tipX: 0.65, activeFinger: .auto), [.tipTap])
    }

    func testLeftFingerRequiresLeftSideTip() {
        XCTAssertEqual(tipTapKinds(baseX: 0.65, tipX: 0.35, activeFinger: .left), [.tipTap])
        XCTAssertTrue(tipTapKinds(baseX: 0.35, tipX: 0.65, activeFinger: .left).isEmpty)
    }

    func testRightFingerRequiresRightSideTip() {
        XCTAssertEqual(tipTapKinds(baseX: 0.35, tipX: 0.65, activeFinger: .right), [.tipTap])
        XCTAssertTrue(tipTapKinds(baseX: 0.65, tipX: 0.35, activeFinger: .right).isEmpty)
    }

    func testLegacyTipTapConfigurationDefaultsToAuto() throws {
        let json = """
        {
          "name": "Tip Tap",
          "isEnabled": true,
          "maximumTapMilliseconds": 300,
          "stationaryMovement": 0.04,
          "tapMovement": 0.06,
          "cooldownMilliseconds": 650,
          "actions": []
        }
        """
        let rule = try JSONDecoder().decode(TipTapGestureRule.self, from: Data(json.utf8))

        XCTAssertEqual(rule.activeFinger, .auto)
    }

    private func tipTapKinds(
        baseX: Double,
        tipX: Double,
        activeFinger: TipTapActiveFinger
    ) -> [RecognizedGesture.Kind] {
        let recognizer = GestureRecognizer(configuration: configuration(activeFinger: activeFinger))
        let base = touch(id: 1, x: baseX)
        let tip = touch(id: 2, x: tipX)

        XCTAssertTrue(recognizer.process(frame(touches: [base], time: 1.0)).isEmpty)
        XCTAssertTrue(recognizer.process(frame(touches: [base, tip], time: 1.05)).isEmpty)
        return recognizer.process(frame(touches: [base], time: 1.12)).map(\.kind)
    }

    private func configuration(activeFinger: TipTapActiveFinger) -> GestureConfiguration {
        GestureConfiguration(triggers: [
            .tipTap(id: "tip", type: .tipTap, rule: rule(activeFinger: activeFinger))
        ])
    }

    private func rule(activeFinger: TipTapActiveFinger) -> TipTapGestureRule {
        TipTapGestureRule(
            name: "Tip Tap",
            isEnabled: true,
            activeFinger: activeFinger,
            cooldownMilliseconds: 650,
            actions: [.testHUD(TestHUDAction(title: "ok"))]
        )
    }

    private func frame(touches: [TouchPoint], time: TimeInterval) -> TouchFrame {
        TouchFrame(touches: touches, timestamp: time, frameNumber: Int(time * 100))
    }

    private func touch(id: Int, x: Double) -> TouchPoint {
        TouchPoint(
            id: id,
            state: .touching,
            position: NormalizedPoint(x: x, y: 0.5),
            pressure: 0.2,
            size: 0.2
        )
    }
}
