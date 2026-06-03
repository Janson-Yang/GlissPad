import AppKit

@MainActor
extension GestureEditorWindowController {
    func makeTwoFingerTouchStartConfigPanel() -> NSView {
        triggerParameterPanel(title: "Two Finger Touch Start Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Cooldown ms", cooldownField),
            makeRegionEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeTwoFingerTapConfigPanel() -> NSView {
        triggerParameterPanel(title: "Two Finger Tap Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Maximum tap ms", tapDurationField),
            triggerFormRow("Movement tolerance", tapMovementField),
            triggerFormRow("Cooldown ms", cooldownField),
            makeRegionEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeTipTapConfigPanel() -> NSView {
        triggerParameterPanel(title: "Tip Tap Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Maximum tap ms", tapDurationField),
            triggerFormRow("Stationary movement", holdMovementField),
            triggerFormRow("Tap movement", tapMovementField),
            triggerFormRow("Cooldown ms", cooldownField),
            makeRegionEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeTwoFingerTransformConfigPanel() -> NSView {
        var views: [NSView] = [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180)
        ]
        views.append(contentsOf: transformThresholdRows())
        if let hint = rotationHintView() {
            views.append(hint)
        }
        views.append(triggerFormRow("Cooldown ms", cooldownField))
        views.append(makeRegionEditor(labelWidth: triggerFormLabelWidth))
        views.append(inspectorButtonRow(saveParametersButton(), deleteTriggerButton()))
        return triggerParameterPanel(title: "Two Finger Transform Configuration", views: views)
    }

    func makeMultiFingerSwipeConfigPanel(needsRegions: Bool) -> NSView {
        var views: [NSView] = [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Path preset", multiFingerSwipePresetPopup, controlWidth: 180),
            triggerFormRow("Point tolerance", pathToleranceField),
            triggerFormRow("Minimum travel", swipeTravelField),
            triggerFormRow("Cooldown ms", cooldownField),
            makePathEditor(labelWidth: triggerFormLabelWidth)
        ]
        if needsRegions {
            views.append(makeSwipeRegionEditors(labelWidth: triggerFormLabelWidth))
        }
        views.append(inspectorButtonRow(saveParametersButton(), deleteTriggerButton()))
        return triggerParameterPanel(title: "Two Finger Swipe Configuration", views: views)
    }

    private func transformThresholdRows() -> [NSView] {
        switch selectedSlot.trigger(in: configuration)?.type {
        case .pinchIn, .pinchOut:
            return [triggerFormRow("Minimum scale change", transformScaleField)]
        case .rotateLeft, .rotateRight:
            return [triggerFormRow("Minimum rotation deg", transformRotationField)]
        default:
            return [
                triggerFormRow("Minimum scale change", transformScaleField),
                triggerFormRow("Minimum rotation deg", transformRotationField)
            ]
        }
    }

    private func rotationHintView() -> NSView? {
        switch selectedSlot.trigger(in: configuration)?.type {
        case .rotateLeft:
            return RotationGestureHintView(direction: .left)
        case .rotateRight:
            return RotationGestureHintView(direction: .right)
        default:
            return nil
        }
    }
}
