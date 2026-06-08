import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func loadTriggerParameters() {
        let selectedType = selectedSlot.trigger(in: configuration)?.type
        configureHoldPressKindOptions(for: selectedType)
        if let rule = selectedSlot.oneFingerRule(in: configuration) {
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            loadRegion(rule.region)
            return
        }
        if let rule = selectedSlot.circleRule(in: configuration) {
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            circleDirectionPopup.selectItem(withTitle: rule.direction.displayName)
            return
        }
        if let rule = selectedSlot.shapeRule(in: configuration) {
            pathToleranceField.stringValue = "\(rule.cornerTolerance)"
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            return
        }
        if let rule = selectedSlot.cornerClickRule(in: configuration) {
            cornerPresetPopup.selectItem(withTitle: rule.corner.displayName)
            cornerClickKindPopup.selectItem(withTitle: rule.clickKind.displayName)
            pressureField.stringValue = "\(rule.minimumPressure)"
            sustainPressureField.stringValue = "\(rule.sustainingPressure)"
            forceMsField.stringValue = "\(rule.minimumForceMilliseconds)"
            cornerMovementField.stringValue = "\(rule.maximumMovement)"
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            loadRegion(rule.region)
            return
        }
        if let rule = selectedSlot.tapRule(in: configuration) {
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            tapDurationField.stringValue = "\(rule.maximumTapMilliseconds)"
            tapIntervalField.stringValue = "\(rule.doubleTapMaximumIntervalMilliseconds)"
            tapMovementField.stringValue = "\(rule.maximumMovement)"
            holdPressKindPopup.selectItem(withTitle: selectedTapPressKind(rule, type: selectedType).displayName)
            pressureField.stringValue = "\(rule.minimumPressure)"
            sustainPressureField.stringValue = "\(rule.sustainingPressure)"
            forceMsField.stringValue = "\(rule.minimumForceMilliseconds)"
            loadRegion(rule.region)
            return
        }
        if let rule = selectedSlot.oneFingerPressRule(in: configuration) {
            oneFingerPressKindPopup.selectItem(withTitle: rule.pressKind.displayName)
            pressureField.stringValue = "\(rule.minimumPressure)"
            sustainPressureField.stringValue = "\(rule.sustainingPressure)"
            forceMsField.stringValue = "\(rule.minimumForceMilliseconds)"
            oneFingerPressMovementField.stringValue = "\(rule.maximumMovement)"
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            return
        }
        if let rule = selectedSlot.customPathRule(in: configuration) {
            pathToleranceField.stringValue = "\(rule.pointTolerance)"
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            rebuildPathPointRows(rule.points)
            drawnPathEditorView.points = rule.points
            return
        }
        if let rule = selectedSlot.touchStartRule(in: configuration) {
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            loadRegion(rule.region)
            return
        }
        if let rule = selectedSlot.tipTapRule(in: configuration) {
            tipTapActiveFingerPopup.selectItem(withTitle: rule.activeFinger.displayName)
            tapDurationField.stringValue = "\(rule.maximumTapMilliseconds)"
            holdMovementField.stringValue = "\(rule.stationaryMovement)"
            tapMovementField.stringValue = "\(rule.tapMovement)"
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            loadRegion(rule.region)
            return
        }
        if let rule = selectedSlot.transformRule(in: configuration) {
            transformScaleField.stringValue = "\(rule.minimumScaleChange)"
            transformRotationField.stringValue = "\(rule.minimumRotationDegrees)"
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            loadRegion(rule.region)
            return
        }
        if let rule = selectedSlot.multiFingerSwipeRule(in: configuration) {
            multiFingerSwipePresetPopup.selectItem(withTitle: rule.pathPreset.displayName)
            pathToleranceField.stringValue = "\(rule.pointTolerance)"
            swipeTravelField.stringValue = "\(rule.minimumTravel)"
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            rebuildPathPointRows(rule.points)
            loadSwipeRegions(start: rule.startRegion, end: rule.endRegion)
            return
        }
        if let rule = selectedSlot.pressRule(in: configuration) {
            requiresClickButton.state = rule.requiresClick ? .on : .off
            pressureField.stringValue = "\(rule.minimumPressure)"
            sustainPressureField.stringValue = "\(rule.sustainingPressure)"
            forceMsField.stringValue = "\(rule.minimumForceMilliseconds)"
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            loadRegion(rule.region)
            return
        }
        if let rule = selectedSlot.threeFingerRule(in: configuration) {
            loadThreeFingerRule(rule)
            return
        }
        if let rule = selectedSlot.fourFingerRule(in: configuration) {
            loadFourFingerRule(rule)
            return
        }
        if let rule = selectedSlot.swipeRule(in: configuration) {
            cooldownField.stringValue = "\(rule.cooldownMilliseconds)"
            swipeTravelField.stringValue = "\(rule.minimumTravel)"
            swipeEdgeWidthField.stringValue = "\(rule.edgeWidth)"
            return
        }
        if let holdRule = selectedSlot.holdRule(in: configuration) {
            cooldownField.stringValue = "\(holdRule.cooldownMilliseconds)"
            holdDurationField.stringValue = "\(holdRule.holdMilliseconds)"
            holdMovementField.stringValue = "\(holdRule.maximumMovement)"
            holdPressKindPopup.selectItem(withTitle: selectedHoldPressKind(holdRule, type: selectedType).displayName)
            holdTriggerTimingPopup.selectItem(withTitle: holdRule.triggerTiming.displayName)
            pressureField.stringValue = "\(holdRule.minimumPressure)"
            sustainPressureField.stringValue = "\(holdRule.sustainingPressure)"
            forceMsField.stringValue = "\(holdRule.minimumForceMilliseconds)"
            loadRegion(holdRule.region)
            return
        }
        guard let releaseRule = selectedSlot.releaseRule(in: configuration) else { return }
        cooldownField.stringValue = "\(releaseRule.cooldownMilliseconds)"
        releaseToleranceField.stringValue = "\(releaseRule.releaseToleranceMilliseconds)"
        releaseFingerCountPopup.selectItem(withTitle: releaseRule.previousFingerCount.displayName)
    }

    func loadSelectedAction(from actions: [GestureAction]) {
        guard actions.indices.contains(selectedAction.index) else {
            actionListTitleLabel.stringValue = "No Action Selected"
            actionNameField.stringValue = ""
            actionTypeLabel.stringValue = ""
            languagePopup.selectItem(withTitle: ScriptLanguage.appleScript.displayName)
            scriptTextView.string = ""
            loadLatencyAction(LatencyAction())
            return
        }
        let action = actions[selectedAction.index]
        actionNameField.stringValue = action.name
        actionListTitleLabel.stringValue = action.name
        actionTypeLabel.stringValue = action.typeDisplayName
        switch action {
        case .script(let scriptAction):
            languagePopup.selectItem(withTitle: scriptAction.language.displayName)
            scriptTextView.string = scriptAction.script
        case .keyboardShortcut(let keyboardAction):
            loadKeyboardShortcutAction(keyboardAction)
        case .testHUD(let testHUDAction):
            loadTestHUDAction(testHUDAction)
        case .latency(let latencyAction):
            loadLatencyAction(latencyAction)
        }
    }

    func updateRegionFields(_ region: NormalizedRegion) {
        regionFields.minX.stringValue = formatRegionCoordinate(region.minX)
        regionFields.maxX.stringValue = formatRegionCoordinate(region.maxX)
        regionFields.minY.stringValue = formatRegionCoordinate(region.minY)
        regionFields.maxY.stringValue = formatRegionCoordinate(region.maxY)
    }

    private func loadRegion(_ region: NormalizedRegion?) {
        let region = region ?? NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1)
        updateRegionFields(region)
        regionSelectionView.region = region
    }

    private func formatRegionCoordinate(_ value: Double) -> String {
        String(format: "%.3g", value)
    }

    private func selectedTapPressKind(_ rule: TapGestureRule, type: GestureTriggerType?) -> HoldPressKind {
        type == .twoFingerTap ? .touch : rule.pressKind
    }

    private func selectedHoldPressKind(_ rule: HoldGestureRule, type: GestureTriggerType?) -> HoldPressKind {
        guard type == .twoFingerHold, rule.pressKind == .forceClick else { return rule.pressKind }
        return .click
    }
}
