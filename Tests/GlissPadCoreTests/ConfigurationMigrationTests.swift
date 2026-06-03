@testable import GlissPadCore
import XCTest

final class ConfigurationMigrationTests: XCTestCase {
    func testMigratesOldKeyboardViewerScript() {
        var configuration = AppConfiguration.default
        configuration.gestures.upperRightForcePress.action = ScriptAction(
            language: .appleScript,
            script: #"tell process "TextInputMenuAgent" to return true"#,
            timeoutSeconds: 5
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertTrue(migrated.gestures.upperRightForcePress.action.script.contains("显示键盘显示程序"))
        XCTAssertEqual(migrated.gestures.upperRightForcePress.minimumPressure, TrackpadPressureThreshold.forceClick)
        XCTAssertTrue(migrated.gestures.upperRightForcePress.requiresClick)
    }

    func testMigratesOldCommandDoubleTapScript() {
        var configuration = AppConfiguration.default
        configuration.gestures.threeFingerForcePress.action = oldCommandDoubleTapScript()

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(migrated.gestures.threeFingerForcePress.action.language, .appleScript)
        XCTAssertEqual(migrated.gestures.threeFingerForcePress.action.script, DefaultScripts.placeholderAppleScript)
        XCTAssertFalse(migrated.gestures.threeFingerForcePress.requiresClick)
        XCTAssertEqual(migrated.gestures.threeFingerForcePress.minimumPressure, TrackpadPressureThreshold.forceClick)
        XCTAssertEqual(migrated.gestures.threeFingerForcePress.minimumForceMilliseconds, 80)
    }

    func testMigratesClickAndForceClickPressureMappings() {
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                .cornerClick(id: "click", type: .oneFingerCornerClick, rule: cornerClickRule()),
                .hold(id: "force-hold", type: .oneFingerLongPress, rule: holdRule(
                    pressKind: .forceClick,
                    minimumPressure: 0.86
                )),
                .hold(id: "touch-hold", type: .oneFingerLongPress, rule: holdRule(pressKind: .touch))
            ]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(pressure(in: migrated.gestures.triggers[0]), TrackpadPressureThreshold.click)
        XCTAssertEqual(pressure(in: migrated.gestures.triggers[1]), TrackpadPressureThreshold.forceClick)
        XCTAssertEqual(pressure(in: migrated.gestures.triggers[2]), 0.2)
    }

    func testMigratesPreviousForceClickDefaults() {
        var forceHold = holdRule(pressKind: .forceClick, minimumPressure: 1.5)
        forceHold.sustainingPressure = 1.2
        var configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                .hold(id: "force-hold", type: .oneFingerLongPress, rule: forceHold)
            ]),
            debugLogging: false
        )
        configuration.gestures.threeFingerForcePress.minimumPressure = 1.5
        configuration.gestures.threeFingerForcePress.sustainingPressure = 1.2

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(migrated.gestures.threeFingerForcePress.minimumPressure, TrackpadPressureThreshold.forceClick)
        XCTAssertEqual(migrated.gestures.threeFingerForcePress.sustainingPressure, TrackpadPressureThreshold.forceClickSustain)
        XCTAssertEqual(pressure(in: migrated.gestures.triggers[0]), TrackpadPressureThreshold.forceClick)
        XCTAssertEqual(sustainPressure(in: migrated.gestures.triggers[0]), TrackpadPressureThreshold.forceClickSustain)
    }

    func testMigratesOldUpperLeftCommandScript() {
        var configuration = AppConfiguration.default
        configuration.gestures.upperLeftForcePress.action = oldCommandDoubleTapScript()

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(migrated.gestures.upperLeftForcePress.action.language, .appleScript)
        XCTAssertEqual(migrated.gestures.upperLeftForcePress.action.script, DefaultScripts.placeholderAppleScript)
        XCTAssertEqual(migrated.gestures.upperLeftForcePress.minimumPressure, TrackpadPressureThreshold.forceClick)
        XCTAssertTrue(migrated.gestures.upperLeftForcePress.requiresClick)
    }

    func testMigratesOldSwipeCommandScript() {
        var configuration = AppConfiguration.default
        configuration.gestures.leftEdgeTwoFingerSwipe.action = oldCommandDoubleTapScript()

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(migrated.gestures.leftEdgeTwoFingerSwipe.action.language, .appleScript)
        XCTAssertEqual(migrated.gestures.leftEdgeTwoFingerSwipe.action.script, DefaultScripts.placeholderAppleScript)
    }

    func testMigratesSwipeEdgeWidth() {
        var configuration = AppConfiguration.default
        configuration.gestures.leftEdgeTwoFingerSwipe.edgeWidth = 0.12

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(migrated.gestures.leftEdgeTwoFingerSwipe.edgeWidth, 0.18)
    }

    func testMigratesOldHoldCommandScript() {
        var configuration = AppConfiguration.default
        configuration.gestures.twoFingerHold.action = oldCommandDoubleTapScript()

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(migrated.gestures.twoFingerHold.action.language, .appleScript)
        XCTAssertEqual(migrated.gestures.twoFingerHold.action.script, DefaultScripts.placeholderAppleScript)
    }

    func testMigratesTwoFingerHoldForceClickToClick() {
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                .hold(id: "hold", type: .twoFingerHold, rule: holdRule(
                    pressKind: .forceClick,
                    minimumPressure: 1.3
                ))
            ]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        guard case .hold(_, .twoFingerHold, let rule) = migrated.gestures.triggers[0] else {
            return XCTFail("Expected two finger hold trigger.")
        }
        XCTAssertEqual(rule.pressKind, .click)
        XCTAssertEqual(rule.minimumPressure, TrackpadPressureThreshold.click)
        XCTAssertEqual(rule.sustainingPressure, TrackpadPressureThreshold.clickSustain)
    }

    func testMigratesTwoFingerTapToTouchOnly() {
        var rule = TapGestureRule(
            name: "Tap",
            isEnabled: true,
            fingerCount: 2,
            tapCount: 1,
            pressKind: .forceClick,
            minimumPressure: 1.3,
            sustainingPressure: 1.0,
            cooldownMilliseconds: 650,
            actions: [.script(oldCommandDoubleTapScript())]
        )
        rule.minimumForceMilliseconds = 45
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [.tap(id: "tap", type: .twoFingerTap, rule: rule)]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        guard case .tap(_, .twoFingerTap, let migratedRule) = migrated.gestures.triggers[0] else {
            return XCTFail("Expected two finger tap trigger.")
        }
        XCTAssertEqual(migratedRule.pressKind, .touch)
        XCTAssertEqual(migratedRule.minimumPressure, TrackpadPressureThreshold.touch)
        XCTAssertEqual(migratedRule.sustainingPressure, TrackpadPressureThreshold.touch)
    }

    func testMigratesTwoFingerTransformSensitivity() {
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                .transform(id: "pinch", type: .pinchIn, rule: transformRule(
                    minimumScaleChange: 0.18,
                    minimumRotationDegrees: 25
                )),
                .transform(id: "rotate", type: .rotateLeft, rule: transformRule(
                    minimumScaleChange: 0.08,
                    minimumRotationDegrees: 14
                ))
            ]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        guard case .transform(_, .pinchIn, let rule) = migrated.gestures.triggers[0] else {
            return XCTFail("Expected transform trigger.")
        }
        XCTAssertEqual(rule.minimumScaleChange, 0.08)
        XCTAssertEqual(rule.minimumRotationDegrees, TwoFingerTransformGestureRule.defaultMinimumRotationDegrees)
        guard case .transform(_, .rotateLeft, let rotateRule) = migrated.gestures.triggers[1] else {
            return XCTFail("Expected rotate trigger.")
        }
        XCTAssertEqual(rotateRule.minimumRotationDegrees, TwoFingerTransformGestureRule.defaultMinimumRotationDegrees)
    }

    func testRemovesRetiredOneFingerPressTriggers() {
        let pressRule = OneFingerPressGestureRule(
            name: "Press 1",
            isEnabled: true,
            pressKind: .click,
            cooldownMilliseconds: 650,
            action: oldCommandDoubleTapScript()
        )
        let configuration = AppConfiguration(
            gestures: GestureConfiguration(triggers: [
                .oneFingerPress(id: "press", type: .oneFingerPress, rule: pressRule),
                GestureTriggerType.oneFingerLongPress.defaultTrigger(id: "longPress", ordinal: 1)
            ]),
            debugLogging: false
        )

        let migrated = configuration.replacingBundledDefaultScripts()

        XCTAssertEqual(migrated.gestures.triggers.map(\.type), [.oneFingerLongPress])
    }

    private func oldCommandDoubleTapScript() -> ScriptAction {
        ScriptAction(
            language: .shell,
            script: "tell application \"System Events\" to key down command",
            timeoutSeconds: 5
        )
    }

    private func cornerClickRule() -> CornerClickGestureRule {
        CornerClickGestureRule(
            name: "Click",
            isEnabled: true,
            corner: .upperRight,
            clickKind: .click,
            minimumPressure: 0.86,
            cooldownMilliseconds: 650,
            region: TrackpadCorner.upperRight.defaultRegion,
            actions: [.script(oldCommandDoubleTapScript())]
        )
    }

    private func holdRule(pressKind: HoldPressKind, minimumPressure: Double = 0.2) -> HoldGestureRule {
        HoldGestureRule(
            name: "Hold",
            isEnabled: true,
            fingerCount: 1,
            holdMilliseconds: 800,
            maximumMovement: 0.04,
            pressKind: pressKind,
            minimumPressure: minimumPressure,
            cooldownMilliseconds: 650,
            action: oldCommandDoubleTapScript()
        )
    }

    private func transformRule(
        minimumScaleChange: Double,
        minimumRotationDegrees: Double
    ) -> TwoFingerTransformGestureRule {
        TwoFingerTransformGestureRule(
            name: "Transform",
            isEnabled: true,
            minimumScaleChange: minimumScaleChange,
            minimumRotationDegrees: minimumRotationDegrees,
            cooldownMilliseconds: 650,
            actions: [.script(oldCommandDoubleTapScript())]
        )
    }

    private func pressure(in rule: GestureRule) -> Double? {
        switch rule {
        case .cornerClick(_, _, let rule):
            return rule.minimumPressure
        case .hold(_, _, let rule):
            return rule.minimumPressure
        default:
            return nil
        }
    }

    private func sustainPressure(in rule: GestureRule) -> Double? {
        switch rule {
        case .cornerClick(_, _, let rule):
            return rule.sustainingPressure
        case .hold(_, _, let rule):
            return rule.sustainingPressure
        default:
            return nil
        }
    }
}
