import AppKit

@MainActor
extension GestureEditorWindowController {
    func makeOneFingerTouchStartConfigPanel() -> NSView {
        triggerParameterPanel(title: "One Finger Gesture Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Cooldown ms", cooldownField),
            makeRegionEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeOneFingerLongPressConfigPanel() -> NSView {
        triggerParameterPanel(title: "One Finger Long Press Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Press type", holdPressKindPopup, controlWidth: 180),
            triggerFormRow("Trigger timing", holdTriggerTimingPopup, controlWidth: 180),
            triggerFormRow("Hold duration ms", holdDurationField),
            triggerFormRow("Activation pressure", pressureField),
            triggerFormRow("Sustain pressure", sustainPressureField),
            triggerFormRow("Minimum force ms", forceMsField),
            triggerFormRow("Movement tolerance", holdMovementField),
            triggerFormRow("Cooldown ms", cooldownField),
            makeRegionEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeOneFingerCircleConfigPanel() -> NSView {
        triggerParameterPanel(title: "One Finger Circle Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Direction", circleDirectionPopup, controlWidth: 180),
            triggerFormRow("Cooldown ms", cooldownField),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeOneFingerShapeConfigPanel() -> NSView {
        triggerParameterPanel(title: "One Finger Shape Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Corner tolerance", pathToleranceField),
            triggerFormRow("Cooldown ms", cooldownField),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeOneFingerCornerClickConfigPanel() -> NSView {
        triggerParameterPanel(title: "One Finger Corner Click Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Corner", cornerPresetPopup, controlWidth: 180),
            triggerFormRow("Click type", cornerClickKindPopup, controlWidth: 180),
            triggerFormRow("Activation pressure", pressureField),
            triggerFormRow("Sustain pressure", sustainPressureField),
            triggerFormRow("Minimum force ms", forceMsField),
            triggerFormRow("Movement tolerance", cornerMovementField),
            triggerFormRow("Cooldown ms", cooldownField),
            makeRegionEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeOneFingerTapConfigPanel(isDoubleTap: Bool) -> NSView {
        var rows = [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Maximum tap ms", tapDurationField),
            triggerFormRow("Movement tolerance", tapMovementField),
            triggerFormRow("Cooldown ms", cooldownField)
        ]
        if isDoubleTap {
            rows.insert(triggerFormRow("Double tap interval ms", tapIntervalField), at: 5)
        }
        rows.append(makeRegionEditor(labelWidth: triggerFormLabelWidth))
        rows.append(inspectorButtonRow(saveParametersButton(), deleteTriggerButton()))
        return triggerParameterPanel(title: "One Finger Tap Configuration", views: rows)
    }

    func makeOneFingerPressConfigPanel() -> NSView {
        triggerParameterPanel(title: "One Finger Press Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Press type", oneFingerPressKindPopup, controlWidth: 180),
            triggerFormRow("Activation pressure", pressureField),
            triggerFormRow("Sustain pressure", sustainPressureField),
            triggerFormRow("Minimum force ms", forceMsField),
            triggerFormRow("Movement tolerance", oneFingerPressMovementField),
            triggerFormRow("Cooldown ms", cooldownField),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeCustomPathConfigPanel() -> NSView {
        triggerParameterPanel(title: "One Finger Custom Path Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Point tolerance", pathToleranceField),
            triggerFormRow("Cooldown ms", cooldownField),
            makePathEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeDrawnPathConfigPanel() -> NSView {
        triggerParameterPanel(title: "One Finger Drawn Path Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Match tolerance", pathToleranceField),
            triggerFormRow("Cooldown ms", cooldownField),
            makeDrawnPathEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }
}
