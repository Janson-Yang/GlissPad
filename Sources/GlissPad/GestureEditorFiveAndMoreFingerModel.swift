import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func loadFiveAndMoreFingerRule(_ rule: FiveAndMoreFingerGestureRule) {
        loadThreeFingerRule(rule.recognitionRule())
        loadFiveAndMoreCommon(rule.common)
        select(fiveAndMoreFingerControls.touchEventPopup, value: rule.touch.event)
        fiveAndMoreFingerControls.touchStableField.stringValue = "\(rule.touch.stableMilliseconds)"
        loadWholeHandTap(rule.wholeHandTap)
    }

    func writeFiveAndMoreFingerRule() throws {
        guard var rule = selectedSlot.fiveAndMoreFingerRule(in: configuration),
              let type = selectedSlot.trigger(in: configuration)?.type else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.common = try visibleFiveAndMoreCommon(type: type)
        try writeFiveAndMoreFamilyOptions(type: type, rule: &rule)
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func loadFiveAndMoreCommon(_ common: ThreeFingerCommonOptions) {
        updateRegionFields(common.region ?? NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1))
        regionSelectionView.region = common.region ?? NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1)
        loadSwipeRegions(start: common.startRegion, end: common.endRegion)
        threeFingerControls.commonInitialGapField.stringValue = "\(common.maxInitialFingerTimeGapMilliseconds)"
        threeFingerControls.commonStableDurationField.stringValue = "\(common.minStableFingerCountDurationMilliseconds)"
    }

    private func loadWholeHandTap(_ options: WholeHandTapOptions) {
        fiveAndMoreFingerControls.wholeHandNominalCountField.stringValue = "\(options.nominalContactCount)"
        fiveAndMoreFingerControls.wholeHandMinimumCountField.stringValue = "\(options.minContactCount)"
        fiveAndMoreFingerControls.wholeHandMaximumCountField.stringValue = options.maxContactCount.map(String.init) ?? ""
        fiveAndMoreFingerControls.wholeHandTotalAreaField.stringValue = "\(options.minTotalContactArea)"
        fiveAndMoreFingerControls.wholeHandAverageAreaField.stringValue = "\(options.minAverageContactArea)"
        fiveAndMoreFingerControls.wholeHandMinimumTapField.stringValue = "\(options.minTapMilliseconds)"
        fiveAndMoreFingerControls.wholeHandMaximumTapField.stringValue = "\(options.maxTapMilliseconds)"
        fiveAndMoreFingerControls.wholeHandMovementField.stringValue = "\(options.maximumMovement)"
        fiveAndMoreFingerControls.requireLargeAreaButton.state = options.requireLargeContactArea ? .on : .off
        fiveAndMoreFingerControls.requirePalmLikeButton.state = options.requirePalmLikeContact ? .on : .off
        select(fiveAndMoreFingerControls.palmDetectionModePopup, value: options.palmDetectionMode)
        guard let region = options.region else { return }
        updateRegionFields(region)
        regionSelectionView.region = region
    }

    private func visibleFiveAndMoreCommon(type: GestureTriggerType) throws -> ThreeFingerCommonOptions {
        ThreeFingerCommonOptions(
            region: usesSingleRegion(type) ? try visibleRegion() : nil,
            startRegion: usesSwipeRegions(type) ? try visibleSwipeStartRegion() : nil,
            endRegion: usesSwipeRegions(type) ? try visibleSwipeEndRegion() : nil,
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

    private func writeFiveAndMoreFamilyOptions(
        type: GestureTriggerType,
        rule: inout FiveAndMoreFingerGestureRule
    ) throws {
        switch type {
        case .fiveFingerTouch:
            rule.touch = try visibleFiveFingerTouch()
        case .fiveFingerTap:
            rule.tap = try visibleThreeFingerTap()
        case .fiveFingerPress:
            rule.press = try visibleFiveFingerPress()
        case .thumbFourFingerScale:
            rule.scale = try visibleThreeFingerScale()
        case .fiveFingerSwipe:
            rule.swipe = try visibleThreeFingerSwipe()
            rule.swipe.pressMode = .none
        case .fiveFingerDrawing:
            rule.drawing = try visibleThreeFingerDrawing(existing: rule.drawing)
        case .wholeHandTap:
            rule.wholeHandTap = try visibleWholeHandTap()
        default:
            return
        }
    }

    private func visibleFiveFingerTouch() throws -> FiveFingerTouchOptions {
        FiveFingerTouchOptions(
            event: try selected(fiveAndMoreFingerControls.touchEventPopup, values: FiveFingerTouchEvent.allCases),
            holdMilliseconds: try intValue(threeFingerControls.touchHoldField, name: "hold duration"),
            stableMilliseconds: try intValue(fiveAndMoreFingerControls.touchStableField, name: "stable duration"),
            movementTolerance: try doubleValue(threeFingerControls.touchMovementField, name: "movement tolerance"),
            cancelOnMovement: threeFingerControls.cancelOnMovementButton.state == .on,
            cancelOnPress: threeFingerControls.cancelOnPressButton.state == .on,
            repeatWhileHolding: threeFingerControls.repeatWhileHoldingButton.state == .on,
            repeatIntervalMilliseconds: try intValue(threeFingerControls.touchRepeatIntervalField, name: "repeat interval"),
            triggerTiming: try selected(threeFingerControls.touchTimingPopup, values: ThreeFingerTriggerTiming.allCases)
        )
    }

    private func visibleFiveFingerPress() throws -> FourFingerPressOptions {
        FourFingerPressOptions(
            level: try selected(threeFingerControls.pressLevelPopup, values: ThreeFingerPressLevel.allCases),
            minimumPressure: try doubleValue(threeFingerControls.pressMinimumField, name: "minimum pressure"),
            forcePressure: try doubleValue(threeFingerControls.pressForceField, name: "force pressure"),
            triggerTiming: try selected(threeFingerControls.pressTimingPopup, values: ThreeFingerPressTriggerTiming.allCases),
            allowFallbackWithoutPressureData: threeFingerControls.fallbackWithoutPressureButton.state == .on
        )
    }

    private func visibleWholeHandTap() throws -> WholeHandTapOptions {
        WholeHandTapOptions(
            nominalContactCount: try intValue(fiveAndMoreFingerControls.wholeHandNominalCountField, name: "nominal count"),
            minContactCount: try intValue(fiveAndMoreFingerControls.wholeHandMinimumCountField, name: "minimum count"),
            maxContactCount: try optionalInt(fiveAndMoreFingerControls.wholeHandMaximumCountField, name: "maximum count"),
            requireLargeContactArea: fiveAndMoreFingerControls.requireLargeAreaButton.state == .on,
            minTotalContactArea: try doubleValue(fiveAndMoreFingerControls.wholeHandTotalAreaField, name: "total area"),
            minAverageContactArea: try doubleValue(fiveAndMoreFingerControls.wholeHandAverageAreaField, name: "average area"),
            requirePalmLikeContact: fiveAndMoreFingerControls.requirePalmLikeButton.state == .on,
            palmDetectionMode: try selected(
                fiveAndMoreFingerControls.palmDetectionModePopup,
                values: WholeHandPalmDetectionMode.allCases
            ),
            minTapMilliseconds: try intValue(fiveAndMoreFingerControls.wholeHandMinimumTapField, name: "minimum tap"),
            maxTapMilliseconds: try intValue(fiveAndMoreFingerControls.wholeHandMaximumTapField, name: "maximum tap"),
            maximumMovement: try doubleValue(fiveAndMoreFingerControls.wholeHandMovementField, name: "movement"),
            region: try visibleRegion()
        )
    }

    private func optionalInt(_ field: NSTextField, name: String) throws -> Int? {
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        guard let intValue = Int(value) else { throw GUIValidationError.invalidField(name) }
        return intValue
    }

    private func usesSingleRegion(_ type: GestureTriggerType) -> Bool {
        type != .fiveFingerSwipe && type != .fiveFingerDrawing && type != .wholeHandTap
    }

    private func usesSwipeRegions(_ type: GestureTriggerType) -> Bool {
        type == .fiveFingerSwipe || type == .fiveFingerDrawing
    }
}
