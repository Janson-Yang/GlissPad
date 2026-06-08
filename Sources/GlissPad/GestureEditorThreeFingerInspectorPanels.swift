import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func makeThreeFingerConfigPanel(type: GestureTriggerType) -> NSView {
        var views = [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 260)
        ]
        views.append(contentsOf: threeFingerRows(for: type))
        views.append(triggerFormRow("Cooldown ms", cooldownField))
        views.append(contentsOf: threeFingerCommonRows())
        views.append(contentsOf: threeFingerRegionRows(for: type))
        views.append(inspectorButtonRow(saveParametersButton(), deleteTriggerButton()))
        return triggerParameterPanel(title: "\(type.displayName) Configuration", views: views)
    }

    private func threeFingerRows(for type: GestureTriggerType) -> [NSView] {
        switch type {
        case .threeFingerTouch, .fourFingerTouch:
            return [
                triggerFormRow("Touch event", threeFingerControls.touchEventPopup, controlWidth: 180),
                triggerFormRow("Trigger timing", threeFingerControls.touchTimingPopup, controlWidth: 180),
                triggerFormRow("Hold duration ms", threeFingerControls.touchHoldField),
                triggerFormRow("Movement tolerance", threeFingerControls.touchMovementField),
                triggerFormRow("Repeat interval ms", threeFingerControls.touchRepeatIntervalField),
                triggerIndented(threeFingerControls.cancelOnMovementButton),
                triggerIndented(threeFingerControls.cancelOnPressButton),
                triggerIndented(threeFingerControls.repeatWhileHoldingButton)
            ]
        case .threeFingerTap, .fourFingerTap:
            return [
                triggerFormRow("Tap count", threeFingerControls.tapCountField),
                triggerFormRow("Maximum tap ms", threeFingerControls.tapDurationField),
                triggerFormRow("Movement tolerance", threeFingerControls.tapMovementField),
                triggerFormRow("Max interval ms", threeFingerControls.tapIntervalField),
                triggerIndented(threeFingerControls.requireNoPressButton)
            ]
        case .threeFingerPress:
            return threeFingerPressRows(includePressureBias: true)
        case .fourFingerPress:
            return threeFingerPressRows(includePressureBias: false)
        case .threeFingerSwipe:
            return threeFingerSwipeRows()
        case .fourFingerSwipe:
            return fourFingerSwipeRows()
        case .threeFingerTipTap:
            return threeFingerTipTapRows()
        case .fourFingerTipTap:
            return fourFingerTipTapRows()
        case .threeFingerTipSwipe:
            return threeFingerTipSwipeRows()
        case .thumbTwoFingerScale, .thumbThreeFingerScale:
            return threeFingerScaleRows()
        case .threeFingerDrawing, .fourFingerDrawing:
            return threeFingerDrawingRows()
        default:
            return []
        }
    }

    private func threeFingerPressRows(includePressureBias: Bool) -> [NSView] {
        var rows = [
            triggerFormRow("Press level", threeFingerControls.pressLevelPopup, controlWidth: 180),
            triggerFormRow("Trigger on", threeFingerControls.pressTimingPopup, controlWidth: 180),
            triggerFormRow("Minimum pressure", threeFingerControls.pressMinimumField),
            triggerFormRow("Force pressure", threeFingerControls.pressForceField),
            triggerIndented(threeFingerControls.fallbackWithoutPressureButton)
        ]
        if includePressureBias {
            rows.insert(triggerFormRow("Pressure bias", threeFingerControls.pressureBiasPopup, controlWidth: 220), at: 1)
            rows.insert(triggerFormRow("Bias threshold", threeFingerControls.pressBiasThresholdField), at: 5)
        }
        return rows
    }

    private func threeFingerSwipeRows() -> [NSView] {
        [
            triggerFormRow("Direction", threeFingerControls.swipeDirectionPopup, controlWidth: 180),
            triggerFormRow("Mode", threeFingerControls.swipePressModePopup, controlWidth: 220),
            triggerFormRow("Trigger timing", threeFingerControls.triggerTimingPopup, controlWidth: 180),
            triggerFormRow("Minimum travel", threeFingerControls.swipeTravelField),
            triggerFormRow("Minimum velocity", threeFingerControls.swipeVelocityField),
            triggerFormRow("Direction tolerance", threeFingerControls.directionToleranceField)
        ]
    }

    private func fourFingerSwipeRows() -> [NSView] {
        [
            triggerFormRow("Direction", threeFingerControls.swipeDirectionPopup, controlWidth: 180),
            triggerFormRow("Trigger timing", threeFingerControls.triggerTimingPopup, controlWidth: 180),
            triggerFormRow("Minimum travel", threeFingerControls.swipeTravelField),
            triggerFormRow("Minimum velocity", threeFingerControls.swipeVelocityField),
            triggerFormRow("Direction tolerance", threeFingerControls.directionToleranceField)
        ]
    }

    private func threeFingerTipTapRows() -> [NSView] {
        [
            triggerFormRow("Tap finger", threeFingerControls.tipTapPositionPopup, controlWidth: 180),
            triggerFormRow("Position reference", threeFingerControls.tipTapReferencePopup, controlWidth: 180),
            triggerFormRow("Tap count", threeFingerControls.tipTapCountField),
            triggerFormRow("Maximum tap ms", threeFingerControls.tipTapDurationField),
            triggerFormRow("Active movement", threeFingerControls.tipTapActiveMovementField),
            triggerFormRow("Fixed movement", threeFingerControls.tipTapFixedMovementField),
            triggerFormRow("Fixed hold ms", threeFingerControls.tipTapFixedHoldField)
        ]
    }

    private func fourFingerTipTapRows() -> [NSView] {
        [
            triggerFormRow("Tap side", threeFingerControls.tipTapPositionPopup, controlWidth: 180),
            triggerFormRow("Side reference", threeFingerControls.tipTapReferencePopup, controlWidth: 220),
            triggerFormRow("Tap count", threeFingerControls.tipTapCountField),
            triggerFormRow("Maximum tap ms", threeFingerControls.tipTapDurationField),
            triggerFormRow("Active movement", threeFingerControls.tipTapActiveMovementField),
            triggerFormRow("Fixed movement", threeFingerControls.tipTapFixedMovementField),
            triggerFormRow("Fixed hold ms", threeFingerControls.tipTapFixedHoldField)
        ]
    }

    private func threeFingerTipSwipeRows() -> [NSView] {
        [
            triggerFormRow("Fixed fingers", threeFingerControls.tipSwipeFixedFingerCountPopup, controlWidth: 180),
            triggerFormRow("Sliding finger", threeFingerControls.tipSwipeActiveFingerPopup, controlWidth: 180),
            triggerFormRow("Direction", threeFingerControls.tipSwipeDirectionPopup, controlWidth: 180),
            triggerFormRow("Trigger timing", threeFingerControls.tipSwipeTimingPopup, controlWidth: 180),
            DisclosureSectionView(title: "Advanced parameters", views: [
                triggerFormRow("Finger reference", threeFingerControls.tipSwipeReferencePopup, controlWidth: 180),
                triggerFormRow("Minimum travel", threeFingerControls.tipSwipeTravelField),
                triggerFormRow("Minimum velocity", threeFingerControls.tipSwipeVelocityField),
                triggerFormRow("Direction tolerance", threeFingerControls.tipSwipeDirectionToleranceField),
                triggerFormRow("Fixed movement", threeFingerControls.tipSwipeFixedMovementField),
                triggerFormRow("Fixed hold ms", threeFingerControls.tipSwipeFixedHoldField)
            ], minimumWidth: triggerFormLabelWidth + 14 + 220)
        ]
    }

    private func threeFingerScaleRows() -> [NSView] {
        [
            triggerFormRow("Scale direction", threeFingerControls.scaleDirectionPopup, controlWidth: 180),
            triggerFormRow("Trigger timing", threeFingerControls.scaleTimingPopup, controlWidth: 180),
            triggerFormRow("Thumb detection", threeFingerControls.thumbModePopup, controlWidth: 220),
            triggerFormRow("Minimum delta", threeFingerControls.scaleDeltaField),
            triggerFormRow("Minimum velocity", threeFingerControls.scaleVelocityField)
        ]
    }

    private func threeFingerDrawingRows() -> [NSView] {
        [
            triggerFormRow("Shape name", threeFingerControls.drawingTemplateNameField, controlWidth: 180),
            triggerFormRow("Path source", threeFingerControls.drawingPathSourcePopup, controlWidth: 180),
            triggerFormRow("Recognition", threeFingerControls.drawingRecognitionPopup, controlWidth: 180),
            triggerFormRow("Score threshold", threeFingerControls.drawingScoreField),
            triggerFormRow("Minimum path", threeFingerControls.drawingMinimumPathField),
            triggerFormRow("Maximum duration ms", threeFingerControls.drawingMaximumDurationField),
            triggerFormRow("Resample count", threeFingerControls.drawingResampleField),
            triggerIndented(threeFingerControls.normalizeScaleButton),
            triggerIndented(threeFingerControls.normalizeRotationButton),
            makeDrawnPathEditor(labelWidth: triggerFormLabelWidth)
        ]
    }

    private func threeFingerRegionRows(for type: GestureTriggerType) -> [NSView] {
        switch type {
        case .threeFingerSwipe, .threeFingerDrawing, .fourFingerSwipe, .fourFingerDrawing:
            return [makeSwipeRegionEditors(labelWidth: triggerFormLabelWidth)]
        default:
            return [makeRegionEditor(labelWidth: triggerFormLabelWidth)]
        }
    }

    private func threeFingerCommonRows() -> [NSView] {
        [
            triggerFormRow("Initial finger gap ms", threeFingerControls.commonInitialGapField),
            triggerFormRow("Stable count ms", threeFingerControls.commonStableDurationField)
        ]
    }
}
