import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func makeFiveAndMoreFingerConfigPanel(type: GestureTriggerType) -> NSView {
        var views = [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 300)
        ]
        views.append(contentsOf: fiveAndMoreRows(for: type))
        views.append(triggerFormRow("Cooldown ms", cooldownField))
        views.append(contentsOf: fiveAndMoreCommonRows(for: type))
        views.append(contentsOf: fiveAndMoreRegionRows(for: type))
        views.append(inspectorButtonRow(saveParametersButton(), deleteTriggerButton()))
        return triggerParameterPanel(title: "\(type.displayName) Configuration", views: views)
    }

    private func fiveAndMoreRows(for type: GestureTriggerType) -> [NSView] {
        switch type {
        case .fiveFingerTouch:
            return fiveFingerTouchRows()
        case .fiveFingerTap:
            return fiveFingerTapRows()
        case .fiveFingerPress:
            return fiveFingerPressRows()
        case .thumbFourFingerScale:
            return fiveFingerScaleRows()
        case .fiveFingerSwipe:
            return fiveFingerSwipeRows()
        case .fiveFingerDrawing:
            return fiveFingerDrawingRows()
        case .wholeHandTap:
            return wholeHandTapRows()
        default:
            return []
        }
    }

    private func fiveFingerTouchRows() -> [NSView] {
        [
            triggerFormRow("Touch event", fiveAndMoreFingerControls.touchEventPopup, controlWidth: 180),
            triggerFormRow("Trigger timing", threeFingerControls.touchTimingPopup, controlWidth: 180),
            triggerFormRow("Hold duration ms", threeFingerControls.touchHoldField),
            triggerFormRow("Stable duration ms", fiveAndMoreFingerControls.touchStableField),
            triggerFormRow("Movement tolerance", threeFingerControls.touchMovementField),
            triggerFormRow("Repeat interval ms", threeFingerControls.touchRepeatIntervalField),
            triggerIndented(threeFingerControls.cancelOnMovementButton),
            triggerIndented(threeFingerControls.cancelOnPressButton),
            triggerIndented(threeFingerControls.repeatWhileHoldingButton)
        ]
    }

    private func fiveFingerTapRows() -> [NSView] {
        [
            triggerFormRow("Tap count", threeFingerControls.tapCountField),
            triggerFormRow("Maximum tap ms", threeFingerControls.tapDurationField),
            triggerFormRow("Movement tolerance", threeFingerControls.tapMovementField),
            triggerFormRow("Max interval ms", threeFingerControls.tapIntervalField),
            triggerIndented(threeFingerControls.requireNoPressButton)
        ]
    }

    private func fiveFingerPressRows() -> [NSView] {
        [
            triggerFormRow("Press level", threeFingerControls.pressLevelPopup, controlWidth: 180),
            triggerFormRow("Trigger on", threeFingerControls.pressTimingPopup, controlWidth: 180),
            triggerFormRow("Minimum pressure", threeFingerControls.pressMinimumField),
            triggerFormRow("Force pressure", threeFingerControls.pressForceField),
            triggerIndented(threeFingerControls.fallbackWithoutPressureButton)
        ]
    }

    private func fiveFingerScaleRows() -> [NSView] {
        [
            triggerFormRow("Scale direction", threeFingerControls.scaleDirectionPopup, controlWidth: 180),
            triggerFormRow("Trigger timing", threeFingerControls.scaleTimingPopup, controlWidth: 180),
            triggerFormRow("Thumb detection", threeFingerControls.thumbModePopup, controlWidth: 220),
            triggerFormRow("Minimum delta", threeFingerControls.scaleDeltaField),
            triggerFormRow("Minimum velocity", threeFingerControls.scaleVelocityField)
        ]
    }

    private func fiveFingerSwipeRows() -> [NSView] {
        [
            triggerFormRow("Direction", threeFingerControls.swipeDirectionPopup, controlWidth: 180),
            triggerFormRow("Trigger timing", threeFingerControls.triggerTimingPopup, controlWidth: 180),
            triggerFormRow("Minimum travel", threeFingerControls.swipeTravelField),
            triggerFormRow("Minimum velocity", threeFingerControls.swipeVelocityField),
            triggerFormRow("Direction tolerance", threeFingerControls.directionToleranceField)
        ]
    }

    private func fiveFingerDrawingRows() -> [NSView] {
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

    private func wholeHandTapRows() -> [NSView] {
        [
            triggerFormRow("Minimum contacts", fiveAndMoreFingerControls.wholeHandMinimumCountField),
            triggerFormRow("Palm detection", fiveAndMoreFingerControls.palmDetectionModePopup, controlWidth: 220),
            triggerFormRow("Maximum tap ms", fiveAndMoreFingerControls.wholeHandMaximumTapField),
            triggerFormRow("Movement tolerance", fiveAndMoreFingerControls.wholeHandMovementField),
            DisclosureSectionView(title: "Advanced parameters", views: wholeHandAdvancedRows(), minimumWidth: 320)
        ]
    }

    private func wholeHandAdvancedRows() -> [NSView] {
        [
            triggerFormRow("Nominal contacts", fiveAndMoreFingerControls.wholeHandNominalCountField),
            triggerFormRow("Maximum contacts", fiveAndMoreFingerControls.wholeHandMaximumCountField),
            triggerFormRow("Minimum tap ms", fiveAndMoreFingerControls.wholeHandMinimumTapField),
            triggerFormRow("Minimum total area", fiveAndMoreFingerControls.wholeHandTotalAreaField),
            triggerFormRow("Minimum average area", fiveAndMoreFingerControls.wholeHandAverageAreaField),
            triggerIndented(fiveAndMoreFingerControls.requireLargeAreaButton),
            triggerIndented(fiveAndMoreFingerControls.requirePalmLikeButton)
        ]
    }

    private func fiveAndMoreCommonRows(for type: GestureTriggerType) -> [NSView] {
        guard type != .wholeHandTap else { return [] }
        return [
            triggerFormRow("Initial finger gap ms", threeFingerControls.commonInitialGapField),
            triggerFormRow("Stable count ms", threeFingerControls.commonStableDurationField)
        ]
    }

    private func fiveAndMoreRegionRows(for type: GestureTriggerType) -> [NSView] {
        switch type {
        case .fiveFingerSwipe, .fiveFingerDrawing:
            return [makeSwipeRegionEditors(labelWidth: triggerFormLabelWidth)]
        default:
            return [makeRegionEditor(labelWidth: triggerFormLabelWidth)]
        }
    }
}
