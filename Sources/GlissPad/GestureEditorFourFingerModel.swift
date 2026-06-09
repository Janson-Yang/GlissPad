import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func loadFourFingerRule(_ rule: FourFingerGestureRule) {
        loadThreeFingerRule(rule.recognitionRule())
        configure(fourFingerTapSidePopup, values: FourFingerTipTapSide.allCases)
        select(fourFingerTapSidePopup, value: rule.tipTap.tapSide)
        configure(fourFingerSideReferencePopup, values: FourFingerTipTapSideReference.allCases)
        select(fourFingerSideReferencePopup, value: rule.tipTap.sideReference)
    }

    func writeFourFingerRule() throws {
        guard var rule = selectedSlot.fourFingerRule(in: configuration),
              let type = selectedSlot.trigger(in: configuration)?.type else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.common = try visibleFourFingerCommon(type: type)
        try writeFourFingerFamilyOptions(type: type, rule: &rule)
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private var fourFingerTapSidePopup: NSPopUpButton {
        threeFingerControls.tipTapPositionPopup
    }

    private var fourFingerSideReferencePopup: NSPopUpButton {
        threeFingerControls.tipTapReferencePopup
    }

    private func visibleFourFingerCommon(type: GestureTriggerType) throws -> ThreeFingerCommonOptions {
        ThreeFingerCommonOptions(
            region: try visibleRegion(),
            startRegion: type == .fourFingerSwipe || type == .fourFingerDrawing ? try visibleSwipeStartRegion() : nil,
            endRegion: type == .fourFingerSwipe || type == .fourFingerDrawing ? try visibleSwipeEndRegion() : nil,
            maxInitialFingerTimeGapMilliseconds: try intValue(
                threeFingerControls.commonInitialGapField,
                name: "initial finger gap"
            ),
            minStableFingerCountDurationMilliseconds: try intValue(
                threeFingerControls.commonStableDurationField,
                name: "stable finger duration"
            )
        )
    }

    private func writeFourFingerFamilyOptions(type: GestureTriggerType, rule: inout FourFingerGestureRule) throws {
        switch type {
        case .fourFingerTouch:
            rule.touch = try visibleThreeFingerTouch()
        case .fourFingerTap:
            rule.tap = try visibleThreeFingerTap()
        case .fourFingerPress:
            rule.press = try visibleFourFingerPress()
        case .fourFingerSwipe:
            rule.swipe = try visibleThreeFingerSwipe()
            rule.swipe.pressMode = .none
        case .thumbThreeFingerScale:
            rule.scale = try visibleThreeFingerScale()
        case .fourFingerTipTap:
            rule.tipTap = try visibleFourFingerTipTap()
        case .fourFingerDrawing:
            rule.drawing = try visibleThreeFingerDrawing(existing: rule.drawing)
        default:
            return
        }
    }

    private func visibleFourFingerPress() throws -> FourFingerPressOptions {
        FourFingerPressOptions(
            level: try selected(threeFingerControls.pressLevelPopup, values: ThreeFingerPressLevel.allCases),
            minimumPressure: try doubleValue(threeFingerControls.pressMinimumField, name: "minimum pressure"),
            forcePressure: try doubleValue(threeFingerControls.pressForceField, name: "force pressure"),
            triggerTiming: try selected(threeFingerControls.pressTimingPopup, values: ThreeFingerPressTriggerTiming.allCases),
            allowFallbackWithoutPressureData: threeFingerControls.fallbackWithoutPressureButton.state == .on
        )
    }

    private func visibleFourFingerTipTap() throws -> FourFingerTipTapOptions {
        FourFingerTipTapOptions(
            tapSide: try selected(fourFingerTapSidePopup, values: FourFingerTipTapSide.allCases),
            sideReference: try selected(fourFingerSideReferencePopup, values: FourFingerTipTapSideReference.allCases),
            tapCount: try intValue(threeFingerControls.tipTapCountField, name: "tip tap count"),
            maximumTapMilliseconds: try intValue(threeFingerControls.tipTapDurationField, name: "tip tap duration"),
            maximumActiveFingerMovement: try doubleValue(threeFingerControls.tipTapActiveMovementField, name: "active movement"),
            maximumFixedFingerMovement: try doubleValue(threeFingerControls.tipTapFixedMovementField, name: "fixed movement"),
            minimumFixedFingerHoldMilliseconds: try intValue(threeFingerControls.tipTapFixedHoldField, name: "fixed hold")
        )
    }
}
