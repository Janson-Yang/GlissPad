import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController: NSTextFieldDelegate, NSTextViewDelegate {
    func configureAutoSavingControls() {
        [
            triggerNameField,
            actionNameField,
            testHUDTitleField,
            testHUDDetailField,
            pressureField,
            sustainPressureField,
            forceMsField,
            cooldownField,
            swipeTravelField,
            swipeEdgeWidthField,
            cornerMovementField,
            tapDurationField,
            tapIntervalField,
            tapMovementField,
            tipTapStationaryMovementField,
            transformScaleField,
            transformRotationField,
            oneFingerPressMovementField,
            pathToleranceField,
            holdDurationField,
            holdMovementField,
            releaseToleranceField,
            keyboardHoldMillisecondsField,
            keyboardPostReleaseDelayField
        ].forEach(configureAutoSavingField)
        [
            regionFields.minX,
            regionFields.maxX,
            regionFields.minY,
            regionFields.maxY,
            swipeStartRegionFields.minX,
            swipeStartRegionFields.maxX,
            swipeStartRegionFields.minY,
            swipeStartRegionFields.maxY,
            swipeEndRegionFields.minX,
            swipeEndRegionFields.maxX,
            swipeEndRegionFields.minY,
            swipeEndRegionFields.maxY
        ].forEach(configureAutoSavingField)
        enabledSwitch.target = self
        enabledSwitch.action = #selector(configurationControlChanged(_:))
        requiresClickButton.target = self
        requiresClickButton.action = #selector(configurationControlChanged(_:))
        scriptTextView.delegate = self
    }

    @objc func configurationControlChanged(_ sender: Any) {
        guard !isLoadingSelection else { return }
        if sender as AnyObject === cornerPresetPopup {
            updateRegionFromSelectedCorner()
        }
        if sender as AnyObject === cornerClickKindPopup {
            syncPressureFieldToSelectedCornerClickKind()
        }
        if sender as AnyObject === oneFingerPressKindPopup {
            syncPressureFieldToSelectedOneFingerPressKind()
        }
        if sender as AnyObject === holdPressKindPopup {
            syncPressureFieldToSelectedHoldPressKind()
        }
        if sender as AnyObject === multiFingerSwipePresetPopup {
            syncPathPointsToSelectedSwipePreset()
        }
        if sender as AnyObject === threeFingerControls.tipSwipeFixedFingerCountPopup {
            syncTipSwipeActiveFingerOptions()
        }
        secondaryKeyField.isEnabled = keyboardModePopup.selectedItem?.title
            == KeyboardShortcutMode.keyCombination.displayName
        commitVisibleEdits(restartActiveListener: true)
        refreshSelectionVisuals()
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        guard !isLoadingSelection else { return }
        commitVisibleEdits(restartActiveListener: true)
        refreshSelectionVisuals()
    }

    func textDidEndEditing(_ notification: Notification) {
        guard !isLoadingSelection else { return }
        commitVisibleEdits(restartActiveListener: true)
        refreshSelectionVisuals()
    }

    private func configureAutoSavingField(_ field: NSTextField) {
        field.delegate = self
        field.target = self
        field.action = #selector(configurationControlChanged(_:))
    }

    private func syncPressureFieldToSelectedCornerClickKind() {
        guard let kind = try? selectedCornerClickKind() else { return }
        pressureField.stringValue = formatPressure(TrackpadPressureThreshold.value(for: kind))
        sustainPressureField.stringValue = formatPressure(TrackpadPressureThreshold.sustain(for: kind))
    }

    private func syncPressureFieldToSelectedOneFingerPressKind() {
        guard let kind = try? selectedOneFingerPressKind() else { return }
        pressureField.stringValue = formatPressure(TrackpadPressureThreshold.value(for: kind))
        sustainPressureField.stringValue = formatPressure(TrackpadPressureThreshold.sustain(for: kind))
    }

    private func syncPressureFieldToSelectedHoldPressKind() {
        guard let kind = try? selectedHoldPressKind() else { return }
        pressureField.stringValue = formatPressure(TrackpadPressureThreshold.value(for: kind))
        sustainPressureField.stringValue = formatPressure(TrackpadPressureThreshold.sustain(for: kind))
    }

    private func syncTipSwipeActiveFingerOptions() {
        let selected = try? selected(threeFingerControls.tipSwipeActiveFingerPopup, values: ThreeFingerActiveFinger.allCases)
        let fixedFingers = (try? selectedTipSwipeFixedFingers()) ?? 2
        let nextSelected = fixedFingers == 1 && selected == .middle ? .auto : selected ?? .auto
        configureTipSwipeActiveFingerPopup(selected: nextSelected, fixedFingers: fixedFingers)
    }

    func configureHoldPressKindOptions(for type: GestureTriggerType?) {
        let kinds = type == .twoFingerHold
            ? HoldPressKind.twoFingerLongPressCases
            : HoldPressKind.allCases
        let titles = kinds.map(\.displayName)
        guard holdPressKindPopup.itemTitles != titles else { return }
        let selected = holdPressKindPopup.selectedItem?.title
        holdPressKindPopup.removeAllItems()
        holdPressKindPopup.addItems(withTitles: titles)
        holdPressKindPopup.selectItem(withTitle: selected ?? HoldPressKind.touch.displayName)
        if holdPressKindPopup.selectedItem == nil {
            holdPressKindPopup.selectItem(withTitle: HoldPressKind.touch.displayName)
        }
    }

    private func formatPressure(_ value: Double) -> String {
        String(format: "%.3g", value)
    }
}
