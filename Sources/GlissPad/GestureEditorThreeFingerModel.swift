import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func loadThreeFingerRule(_ rule: ThreeFingerGestureRule) {
        cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
        loadThreeFingerCommon(rule.common)
        select(threeFingerControls.touchEventPopup, value: rule.touch.event)
        select(threeFingerControls.touchTimingPopup, value: rule.touch.triggerTiming)
        threeFingerControls.touchHoldField.stringValue = "\(rule.touch.holdMilliseconds)"
        threeFingerControls.touchMovementField.stringValue = "\(rule.touch.movementTolerance)"
        threeFingerControls.touchRepeatIntervalField.stringValue = "\(rule.touch.repeatIntervalMilliseconds)"
        threeFingerControls.cancelOnMovementButton.state = rule.touch.cancelOnMovement ? .on : .off
        threeFingerControls.cancelOnPressButton.state = rule.touch.cancelOnPress ? .on : .off
        threeFingerControls.repeatWhileHoldingButton.state = rule.touch.repeatWhileHolding ? .on : .off
        loadThreeFingerTap(rule.tap)
        loadThreeFingerPress(rule.press)
        loadThreeFingerMovement(rule)
        loadThreeFingerDrawing(rule.drawing)
    }

    func writeThreeFingerRule() throws {
        guard var rule = selectedSlot.threeFingerRule(in: configuration),
              let type = selectedSlot.trigger(in: configuration)?.type else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.common = try visibleThreeFingerCommon(type: type)
        try writeThreeFingerFamilyOptions(type: type, rule: &rule)
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func loadThreeFingerCommon(_ common: ThreeFingerCommonOptions) {
        loadRegionForThreeFinger(common.region)
        loadSwipeRegions(start: common.startRegion, end: common.endRegion)
        threeFingerControls.commonInitialGapField.stringValue = "\(common.maxInitialFingerTimeGapMilliseconds)"
        threeFingerControls.commonStableDurationField.stringValue = "\(common.minStableFingerCountDurationMilliseconds)"
    }

    private func loadThreeFingerTap(_ tap: ThreeFingerTapOptions) {
        threeFingerControls.tapCountField.stringValue = "\(tap.tapCount)"
        threeFingerControls.tapDurationField.stringValue = "\(tap.maximumTapMilliseconds)"
        threeFingerControls.tapMovementField.stringValue = "\(tap.maximumMovement)"
        threeFingerControls.tapIntervalField.stringValue = "\(tap.maximumInterTapIntervalMilliseconds)"
        threeFingerControls.requireNoPressButton.state = tap.requireNoPress ? .on : .off
    }

    private func loadThreeFingerPress(_ press: ThreeFingerPressOptions) {
        select(threeFingerControls.pressLevelPopup, value: press.level)
        select(threeFingerControls.pressureBiasPopup, value: press.pressureBias)
        select(threeFingerControls.pressTimingPopup, value: press.triggerTiming)
        threeFingerControls.pressMinimumField.stringValue = "\(press.minimumPressure)"
        threeFingerControls.pressForceField.stringValue = "\(press.forcePressure)"
        threeFingerControls.pressBiasThresholdField.stringValue = "\(press.pressureBiasThreshold)"
        threeFingerControls.fallbackWithoutPressureButton.state = press.allowFallbackWithoutPressureData ? .on : .off
    }

    private func loadThreeFingerMovement(_ rule: ThreeFingerGestureRule) {
        select(threeFingerControls.swipeDirectionPopup, value: rule.swipe.direction)
        select(threeFingerControls.swipePressModePopup, value: rule.swipe.pressMode)
        select(threeFingerControls.triggerTimingPopup, value: rule.swipe.triggerTiming)
        threeFingerControls.swipeTravelField.stringValue = "\(rule.swipe.minimumTravel)"
        threeFingerControls.swipeVelocityField.stringValue = "\(rule.swipe.minimumVelocity)"
        threeFingerControls.directionToleranceField.stringValue = "\(rule.swipe.directionToleranceDegrees)"
        select(threeFingerControls.tipTapPositionPopup, value: rule.tipTap.tapPosition)
        configureFingerReferencePopup(threeFingerControls.tipTapReferencePopup, selected: rule.tipTap.positionReference)
        let fixedFingerCount = TipSwipeFixedFingerCountOption.option(for: rule.tipSwipe.fixedFingers)
        select(threeFingerControls.tipSwipeFixedFingerCountPopup, value: fixedFingerCount)
        configureTipSwipeActiveFingerPopup(
            selected: rule.tipSwipe.activeFinger,
            fixedFingers: rule.tipSwipe.fixedFingers
        )
        configureFingerReferencePopup(threeFingerControls.tipSwipeReferencePopup, selected: rule.tipSwipe.activeFingerReference)
        select(threeFingerControls.tipSwipeDirectionPopup, value: rule.tipSwipe.direction)
        select(threeFingerControls.tipSwipeTimingPopup, value: rule.tipSwipe.triggerTiming)
        select(threeFingerControls.scaleDirectionPopup, value: rule.scale.direction)
        select(threeFingerControls.scaleTimingPopup, value: rule.scale.triggerTiming)
        select(threeFingerControls.thumbModePopup, value: rule.scale.thumbDetectionMode)
        loadThreeFingerMovementFields(rule)
    }

    private func loadThreeFingerMovementFields(_ rule: ThreeFingerGestureRule) {
        threeFingerControls.tipTapCountField.stringValue = "\(rule.tipTap.tapCount)"
        threeFingerControls.tipTapDurationField.stringValue = "\(rule.tipTap.maximumTapMilliseconds)"
        threeFingerControls.tipTapActiveMovementField.stringValue = "\(rule.tipTap.maximumActiveFingerMovement)"
        threeFingerControls.tipTapFixedMovementField.stringValue = "\(rule.tipTap.maximumFixedFingerMovement)"
        threeFingerControls.tipTapFixedHoldField.stringValue = "\(rule.tipTap.minimumFixedFingerHoldMilliseconds)"
        threeFingerControls.tipSwipeTravelField.stringValue = "\(rule.tipSwipe.minimumTravel)"
        threeFingerControls.tipSwipeVelocityField.stringValue = "\(rule.tipSwipe.minimumVelocity)"
        threeFingerControls.tipSwipeDirectionToleranceField.stringValue = "\(rule.tipSwipe.directionToleranceDegrees)"
        threeFingerControls.tipSwipeFixedMovementField.stringValue = "\(rule.tipSwipe.maximumFixedFingerMovement)"
        threeFingerControls.tipSwipeFixedHoldField.stringValue = "\(rule.tipSwipe.minimumFixedFingerHoldMilliseconds)"
        threeFingerControls.scaleDeltaField.stringValue = "\(rule.scale.minimumScaleDelta)"
        threeFingerControls.scaleVelocityField.stringValue = "\(rule.scale.minimumScaleVelocity)"
    }

    private func loadThreeFingerDrawing(_ drawing: ThreeFingerDrawingOptions) {
        select(threeFingerControls.drawingPathSourcePopup, value: drawing.pathSource)
        select(threeFingerControls.drawingRecognitionPopup, value: drawing.recognitionMode)
        threeFingerControls.drawingTemplateNameField.stringValue = drawing.template.name
        threeFingerControls.drawingScoreField.stringValue = "\(drawing.scoreThreshold)"
        threeFingerControls.drawingMinimumPathField.stringValue = "\(drawing.minimumPathLength)"
        threeFingerControls.drawingMaximumDurationField.stringValue = "\(drawing.maximumDurationMilliseconds)"
        threeFingerControls.drawingResampleField.stringValue = "\(drawing.resamplePointCount)"
        threeFingerControls.normalizeScaleButton.state = drawing.normalizeScale ? .on : .off
        threeFingerControls.normalizeRotationButton.state = drawing.normalizeRotation ? .on : .off
        drawnPathEditorView.points = drawing.template.points
    }

    private func visibleThreeFingerCommon(type: GestureTriggerType) throws -> ThreeFingerCommonOptions {
        ThreeFingerCommonOptions(
            region: try visibleRegion(),
            startRegion: type == .threeFingerSwipe || type == .threeFingerDrawing ? try visibleSwipeStartRegion() : nil,
            endRegion: type == .threeFingerSwipe || type == .threeFingerDrawing ? try visibleSwipeEndRegion() : nil,
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

    private func loadRegionForThreeFinger(_ region: NormalizedRegion?) {
        updateRegionFields(region ?? NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1))
        regionSelectionView.region = region ?? NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1)
    }
}
