import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func loadSelectedRule() {
        normalizeSelectedTrigger()
        isLoadingSelection = true
        defer { isLoadingSelection = false }
        guard selectedSlot.trigger(in: configuration) != nil else {
            loadEmptyTriggerSelection()
            return
        }
        let actions = selectedSlot.actions(in: configuration)
        selectedAction.index = actions.isEmpty
            ? 0
            : min(selectedAction.index, actions.count - 1)
        if actions.isEmpty, inspectorMode == .action {
            inspectorMode = .trigger
        }
        let triggerName = selectedSlot.displayName(in: configuration)
        titleLabel.stringValue = triggerName
        triggerNameField.stringValue = triggerName
        activeTriggerLabel.stringValue = selectedSlot.title(in: configuration)
        enabledSwitch.state = selectedSlot.isEnabled(in: configuration) ? .on : .off
        updateTriggerEnabledSwitch()
        loadTriggerParameters()
        loadSelectedAction(from: actions)
        rebuildActionList()
        updateActionListCopy()
        rebuildInspector()
    }

    func writeVisibleRule() throws {
        switch selectedSlot.trigger(in: configuration) {
        case .oneFinger?:
            try writeOneFingerRule()
        case .circle?:
            try writeCircleRule()
        case .shape?:
            try writeShapeRule()
        case .cornerClick?:
            try writeCornerClickRule()
        case .tap?:
            try writeTapRule()
        case .oneFingerPress?:
            try writeOneFingerPressRule()
        case .customPath?:
            try writeCustomPathRule()
        case .touchStart?:
            try writeTouchStartRule()
        case .tipTap?:
            try writeTipTapRule()
        case .transform?:
            try writeTransformRule()
        case .multiFingerSwipe?:
            try writeMultiFingerSwipeRule()
        case .swipe?:
            try writeSwipeRule()
        case .hold?:
            try writeHoldRule()
        case .release?:
            try writeReleaseRule()
        case .press?:
            try writePressRule()
        case .threeFinger?:
            try writeThreeFingerRule()
        case .fourFinger?:
            try writeFourFingerRule()
        case nil:
            return
        }
    }

    private func writeOneFingerRule() throws {
        guard var rule = selectedSlot.oneFingerRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.region = try visibleRegion()
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeCircleRule() throws {
        guard var rule = selectedSlot.circleRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.direction = try selectedCircleDirection()
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeCornerClickRule() throws {
        guard var rule = selectedSlot.cornerClickRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.corner = try selectedTrackpadCorner()
        rule.clickKind = try selectedCornerClickKind()
        rule.minimumPressure = try doubleValue(pressureField, name: "pressure")
        rule.sustainingPressure = try doubleValue(sustainPressureField, name: "sustain pressure")
        rule.minimumForceMilliseconds = try intValue(forceMsField, name: "minimum force")
        rule.maximumMovement = try doubleValue(cornerMovementField, name: "movement tolerance")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.region = try visibleRegion() ?? rule.region
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeTapRule() throws {
        guard var rule = selectedSlot.tapRule(in: configuration) else { return }
        let type = selectedSlot.trigger(in: configuration)?.type
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.fingerCount = type == .twoFingerTap ? 2 : 1
        rule.tapCount = type == .oneFingerDoubleTap ? 2 : 1
        rule.maximumTapMilliseconds = try intValue(tapDurationField, name: "maximum tap duration")
        rule.doubleTapMaximumIntervalMilliseconds = try intValue(tapIntervalField, name: "double tap interval")
        rule.maximumMovement = try doubleValue(tapMovementField, name: "movement tolerance")
        if type == .twoFingerTap {
            rule.pressKind = .touch
            rule.minimumPressure = TrackpadPressureThreshold.touch
            rule.sustainingPressure = TrackpadPressureThreshold.touch
            rule.minimumForceMilliseconds = 0
        }
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.region = try visibleRegion()
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeOneFingerPressRule() throws {
        guard var rule = selectedSlot.oneFingerPressRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.pressKind = try selectedOneFingerPressKind()
        rule.minimumPressure = try doubleValue(pressureField, name: "pressure")
        rule.sustainingPressure = try doubleValue(sustainPressureField, name: "sustain pressure")
        rule.minimumForceMilliseconds = try intValue(forceMsField, name: "minimum force")
        rule.maximumMovement = try doubleValue(oneFingerPressMovementField, name: "movement tolerance")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeCustomPathRule() throws {
        guard var rule = selectedSlot.customPathRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.pointTolerance = try doubleValue(pathToleranceField, name: "point tolerance")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.points = try visibleCustomPathPoints()
        pathEditorView.points = rule.points
        drawnPathEditorView.points = rule.points
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writePressRule() throws {
        guard var rule = selectedSlot.pressRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.requiresClick = requiresClickButton.state == .on
        rule.minimumPressure = try doubleValue(pressureField, name: "pressure")
        rule.sustainingPressure = try doubleValue(sustainPressureField, name: "sustain pressure")
        rule.minimumForceMilliseconds = try intValue(forceMsField, name: "minimum force")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.region = try visibleRegion()
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeReleaseRule() throws {
        guard var rule = selectedSlot.releaseRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.previousFingerCount = try selectedReleaseFingerCount()
        rule.releaseToleranceMilliseconds = try intValue(releaseToleranceField, name: "release tolerance")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeSwipeRule() throws {
        guard var rule = selectedSlot.swipeRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.minimumTravel = try doubleValue(swipeTravelField, name: "minimum travel")
        rule.edgeWidth = try doubleValue(swipeEdgeWidthField, name: "edge width")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeMultiFingerSwipeRule() throws {
        guard var rule = selectedSlot.multiFingerSwipeRule(in: configuration) else { return }
        let type = selectedSlot.trigger(in: configuration)?.type
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.pathPreset = try selectedMultiFingerSwipePreset()
        rule.pointTolerance = try doubleValue(pathToleranceField, name: "point tolerance")
        rule.minimumTravel = try doubleValue(swipeTravelField, name: "minimum travel")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.points = try visiblePathPoints()
        if type == .regionTwoFingerSwipe {
            rule.startRegion = try visibleSwipeStartRegion()
            rule.endRegion = try visibleSwipeEndRegion()
        } else {
            rule.startRegion = nil
            rule.endRegion = nil
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func writeHoldRule() throws {
        guard var rule = selectedSlot.holdRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.holdMilliseconds = try intValue(holdDurationField, name: "hold duration")
        rule.maximumMovement = try doubleValue(holdMovementField, name: "movement tolerance")
        rule.pressKind = try selectedHoldPressKind()
        if selectedSlot.trigger(in: configuration)?.type == .twoFingerHold, rule.pressKind == .forceClick {
            rule.pressKind = .click
        }
        rule.triggerTiming = try selectedHoldTriggerTiming()
        rule.minimumPressure = try doubleValue(pressureField, name: "pressure")
        rule.sustainingPressure = try doubleValue(sustainPressureField, name: "sustain pressure")
        rule.minimumForceMilliseconds = try intValue(forceMsField, name: "minimum force")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.region = try visibleRegion()
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    private func normalizeSelectedTrigger() {
        if configuration.gestures.triggers.isEmpty {
            selectedSlot = GestureSlot(index: 0)
            return
        }
        selectedSlot.index = min(selectedSlot.index, configuration.gestures.triggers.count - 1)
    }

    private func loadEmptyTriggerSelection() {
        selectedAction = ActionSlot(index: 0)
        inspectorMode = .trigger
        titleLabel.stringValue = "No Trigger Selected"
        triggerNameField.stringValue = ""
        activeTriggerLabel.stringValue = ""
        enabledSwitch.state = .off
        updateTriggerEnabledSwitch()
        loadSelectedAction(from: [])
        rebuildActionList()
        updateActionListCopy()
        rebuildInspector()
    }

}
