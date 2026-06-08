import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func writeThreeFingerFamilyOptions(type: GestureTriggerType, rule: inout ThreeFingerGestureRule) throws {
        switch type {
        case .threeFingerTouch:
            rule.touch = try visibleThreeFingerTouch()
        case .threeFingerTap:
            rule.tap = try visibleThreeFingerTap()
        case .threeFingerPress:
            rule.press = try visibleThreeFingerPress()
        case .threeFingerSwipe:
            rule.swipe = try visibleThreeFingerSwipe()
        case .threeFingerTipTap:
            rule.tipTap = try visibleThreeFingerTipTap()
        case .threeFingerTipSwipe:
            rule.tipSwipe = try visibleThreeFingerTipSwipe()
        case .thumbTwoFingerScale:
            rule.scale = try visibleThreeFingerScale()
        case .threeFingerDrawing:
            rule.drawing = try visibleThreeFingerDrawing(existing: rule.drawing)
        default:
            return
        }
    }

    func visibleThreeFingerTouch() throws -> ThreeFingerTouchOptions {
        ThreeFingerTouchOptions(
            event: try selected(threeFingerControls.touchEventPopup, values: ThreeFingerTouchEvent.allCases),
            holdMilliseconds: try intValue(threeFingerControls.touchHoldField, name: "hold duration"),
            movementTolerance: try doubleValue(threeFingerControls.touchMovementField, name: "movement tolerance"),
            cancelOnMovement: threeFingerControls.cancelOnMovementButton.state == .on,
            cancelOnPress: threeFingerControls.cancelOnPressButton.state == .on,
            repeatWhileHolding: threeFingerControls.repeatWhileHoldingButton.state == .on,
            repeatIntervalMilliseconds: try intValue(
                threeFingerControls.touchRepeatIntervalField,
                name: "repeat interval"
            ),
            triggerTiming: try selected(
                threeFingerControls.touchTimingPopup,
                values: ThreeFingerTriggerTiming.allCases
            )
        )
    }

    func visibleThreeFingerTap() throws -> ThreeFingerTapOptions {
        ThreeFingerTapOptions(
            tapCount: try intValue(threeFingerControls.tapCountField, name: "tap count"),
            maximumTapMilliseconds: try intValue(threeFingerControls.tapDurationField, name: "tap duration"),
            maximumMovement: try doubleValue(threeFingerControls.tapMovementField, name: "tap movement"),
            maximumInterTapIntervalMilliseconds: try intValue(threeFingerControls.tapIntervalField, name: "tap interval"),
            requireNoPress: threeFingerControls.requireNoPressButton.state == .on
        )
    }

    private func visibleThreeFingerPress() throws -> ThreeFingerPressOptions {
        ThreeFingerPressOptions(
            level: try selected(threeFingerControls.pressLevelPopup, values: ThreeFingerPressLevel.allCases),
            pressureBias: try selected(threeFingerControls.pressureBiasPopup, values: ThreeFingerPressureBias.allCases),
            minimumPressure: try doubleValue(threeFingerControls.pressMinimumField, name: "minimum pressure"),
            forcePressure: try doubleValue(threeFingerControls.pressForceField, name: "force pressure"),
            pressureBiasThreshold: try doubleValue(threeFingerControls.pressBiasThresholdField, name: "bias threshold"),
            triggerTiming: try selected(threeFingerControls.pressTimingPopup, values: ThreeFingerPressTriggerTiming.allCases),
            allowFallbackWithoutPressureData: threeFingerControls.fallbackWithoutPressureButton.state == .on
        )
    }

    func visibleThreeFingerSwipe() throws -> ThreeFingerSwipeOptions {
        ThreeFingerSwipeOptions(
            direction: try selected(threeFingerControls.swipeDirectionPopup, values: ThreeFingerDirection.allCases),
            pressMode: try selected(threeFingerControls.swipePressModePopup, values: ThreeFingerSwipePressMode.allCases),
            minimumTravel: try doubleValue(threeFingerControls.swipeTravelField, name: "minimum travel"),
            minimumVelocity: try doubleValue(threeFingerControls.swipeVelocityField, name: "minimum velocity"),
            directionToleranceDegrees: try doubleValue(threeFingerControls.directionToleranceField, name: "direction tolerance"),
            triggerTiming: try selected(threeFingerControls.triggerTimingPopup, values: ThreeFingerTriggerTiming.allCases)
        )
    }

    private func visibleThreeFingerTipTap() throws -> ThreeFingerTipTapOptions {
        ThreeFingerTipTapOptions(
            tapPosition: try selected(threeFingerControls.tipTapPositionPopup, values: ThreeFingerActiveFinger.allCases),
            positionReference: try selected(threeFingerControls.tipTapReferencePopup, values: ThreeFingerFingerReference.allCases),
            tapCount: try intValue(threeFingerControls.tipTapCountField, name: "tip tap count"),
            maximumTapMilliseconds: try intValue(threeFingerControls.tipTapDurationField, name: "tip tap duration"),
            maximumActiveFingerMovement: try doubleValue(threeFingerControls.tipTapActiveMovementField, name: "active movement"),
            maximumFixedFingerMovement: try doubleValue(threeFingerControls.tipTapFixedMovementField, name: "fixed movement"),
            minimumFixedFingerHoldMilliseconds: try intValue(threeFingerControls.tipTapFixedHoldField, name: "fixed hold")
        )
    }

    private func visibleThreeFingerTipSwipe() throws -> ThreeFingerTipSwipeOptions {
        ThreeFingerTipSwipeOptions(
            fixedFingers: try selectedTipSwipeFixedFingers(),
            activeFinger: try selected(threeFingerControls.tipSwipeActiveFingerPopup, values: ThreeFingerActiveFinger.allCases),
            activeFingerReference: try selected(threeFingerControls.tipSwipeReferencePopup, values: ThreeFingerFingerReference.allCases),
            direction: try selected(threeFingerControls.tipSwipeDirectionPopup, values: ThreeFingerDirection.allCases),
            minimumTravel: try doubleValue(threeFingerControls.tipSwipeTravelField, name: "tip swipe travel"),
            minimumVelocity: try doubleValue(threeFingerControls.tipSwipeVelocityField, name: "tip swipe velocity"),
            directionToleranceDegrees: try doubleValue(
                threeFingerControls.tipSwipeDirectionToleranceField,
                name: "tip swipe direction tolerance"
            ),
            maximumFixedFingerMovement: try doubleValue(threeFingerControls.tipSwipeFixedMovementField, name: "fixed movement"),
            minimumFixedFingerHoldMilliseconds: try intValue(threeFingerControls.tipSwipeFixedHoldField, name: "fixed hold"),
            triggerTiming: try selected(
                threeFingerControls.tipSwipeTimingPopup,
                values: ThreeFingerTriggerTiming.allCases
            )
        )
    }

    func visibleThreeFingerScale() throws -> ThreeFingerScaleOptions {
        ThreeFingerScaleOptions(
            direction: try selected(threeFingerControls.scaleDirectionPopup, values: ThreeFingerScaleDirection.allCases),
            minimumScaleDelta: try doubleValue(threeFingerControls.scaleDeltaField, name: "scale delta"),
            minimumScaleVelocity: try doubleValue(threeFingerControls.scaleVelocityField, name: "scale velocity"),
            triggerTiming: try selected(threeFingerControls.scaleTimingPopup, values: ThreeFingerTriggerTiming.allCases),
            thumbDetectionMode: try selected(threeFingerControls.thumbModePopup, values: ThreeFingerThumbDetectionMode.allCases)
        )
    }

    func visibleThreeFingerDrawing(existing: ThreeFingerDrawingOptions) throws -> ThreeFingerDrawingOptions {
        ThreeFingerDrawingOptions(
            template: ThreeFingerDrawingTemplate(
                id: existing.template.id,
                name: try nonEmptyString(threeFingerControls.drawingTemplateNameField, name: "drawing name"),
                points: drawnPathEditorView.points
            ),
            pathSource: try selected(threeFingerControls.drawingPathSourcePopup, values: ThreeFingerDrawingPathSource.allCases),
            recognitionMode: try selected(threeFingerControls.drawingRecognitionPopup, values: ThreeFingerDrawingRecognitionMode.allCases),
            scoreThreshold: try doubleValue(threeFingerControls.drawingScoreField, name: "score threshold"),
            minimumPathLength: try doubleValue(threeFingerControls.drawingMinimumPathField, name: "minimum path"),
            maximumDurationMilliseconds: try intValue(threeFingerControls.drawingMaximumDurationField, name: "maximum duration"),
            normalizeRotation: threeFingerControls.normalizeRotationButton.state == .on,
            normalizeScale: threeFingerControls.normalizeScaleButton.state == .on,
            resamplePointCount: try intValue(threeFingerControls.drawingResampleField, name: "resample count")
        )
    }
}
