import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func configureEditor() {
        LiquidGlassStyle.configureTitle(titleLabel)
        LiquidGlassStyle.configureStatus(statusLabel)
        configureTriggerEnabledSwitch()
        activeTriggerLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        activeTriggerLabel.alignment = .left
        activeTriggerLabel.cell?.alignment = .left
        actionTypeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        actionTypeLabel.alignment = .left
        actionTypeLabel.cell?.alignment = .left
        actionListTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        actionListTitleLabel.alignment = .left
        actionListTitleLabel.cell?.alignment = .left
        actionListTitleLabel.lineBreakMode = .byTruncatingTail
        triggerNameField.placeholderString = "Trigger name"
        actionNameField.placeholderString = "Action name"
        testHUDTitleField.placeholderString = "HUD title"
        testHUDDetailField.placeholderString = "HUD detail"
        requiresClickButton.controlSize = .large
        releaseFingerCountPopup.controlSize = .large
        releaseFingerCountPopup.addItems(withTitles: ReleaseFingerCount.menuOptions.map(\.displayName))
        releaseFingerCountPopup.target = self
        releaseFingerCountPopup.action = #selector(configurationControlChanged(_:))
        circleDirectionPopup.controlSize = .large
        circleDirectionPopup.addItems(withTitles: CircleDirection.allCases.map(\.displayName))
        circleDirectionPopup.target = self
        circleDirectionPopup.action = #selector(configurationControlChanged(_:))
        cornerPresetPopup.controlSize = .large
        cornerPresetPopup.addItems(withTitles: TrackpadCorner.allCases.map(\.displayName))
        cornerPresetPopup.target = self
        cornerPresetPopup.action = #selector(configurationControlChanged(_:))
        cornerClickKindPopup.controlSize = .large
        cornerClickKindPopup.addItems(withTitles: CornerClickKind.allCases.map(\.displayName))
        cornerClickKindPopup.target = self
        cornerClickKindPopup.action = #selector(configurationControlChanged(_:))
        oneFingerPressKindPopup.controlSize = .large
        oneFingerPressKindPopup.addItems(withTitles: OneFingerPressKind.allCases.map(\.displayName))
        oneFingerPressKindPopup.target = self
        oneFingerPressKindPopup.action = #selector(configurationControlChanged(_:))
        holdPressKindPopup.controlSize = .large
        configureHoldPressKindOptions(for: nil)
        holdPressKindPopup.target = self
        holdPressKindPopup.action = #selector(configurationControlChanged(_:))
        holdTriggerTimingPopup.controlSize = .large
        holdTriggerTimingPopup.addItems(withTitles: HoldTriggerTiming.allCases.map(\.displayName))
        holdTriggerTimingPopup.target = self
        holdTriggerTimingPopup.action = #selector(configurationControlChanged(_:))
        multiFingerSwipePresetPopup.controlSize = .large
        multiFingerSwipePresetPopup.addItems(withTitles: MultiFingerSwipePathPreset.allCases.map(\.displayName))
        multiFingerSwipePresetPopup.target = self
        multiFingerSwipePresetPopup.action = #selector(configurationControlChanged(_:))
        languagePopup.controlSize = .large
        languagePopup.addItems(withTitles: ScriptLanguage.allCases.map(\.displayName))
        languagePopup.target = self
        languagePopup.action = #selector(scriptLanguageChanged(_:))
        configureScriptModeHelp()
        configureKeyboardControls()
        scriptTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        scriptTextView.textColor = .labelColor
        scriptTextView.backgroundColor = .clear
        scriptTextView.drawsBackground = false
        scriptTextView.insertionPointColor = .controlAccentColor
        scriptTextView.textContainerInset = NSSize(width: 12, height: 10)
        scriptTextView.textContainer?.lineFragmentPadding = 0
        scriptTextView.textContainer?.widthTracksTextView = true
        scriptTextView.isHorizontallyResizable = false
        scriptTextView.isVerticallyResizable = true
        scriptTextView.autoresizingMask = [.width]
        scriptTextView.isAutomaticQuoteSubstitutionEnabled = false
        scriptTextView.isAutomaticDashSubstitutionEnabled = false
        configureAutoSavingControls()
        configureRegionSelection()
        configureSwipeRegionSelection()
        configurePathEditor()
        configureDrawnPathEditor()
    }

    private func configureKeyboardControls() {
        keyboardModePopup.controlSize = .large
        keyboardModePopup.addItems(withTitles: KeyboardShortcutMode.allCases.map(\.displayName))
        keyboardModePopup.target = self
        keyboardModePopup.action = #selector(configurationControlChanged(_:))
        primaryKeyField.placeholder = "Press primary key"
        secondaryKeyField.placeholder = "Press second key"
        [primaryKeyField, secondaryKeyField].forEach { field in
            field.target = self
            field.action = #selector(configurationControlChanged(_:))
            field.widthAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        }
    }

    func makeScriptEditor() -> NSView {
        let label = NSTextField(labelWithString: "Script")
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.cell?.alignment = .left
        let scrollView = RoundedScriptScrollView()
        scrollView.documentView = scriptTextView
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true
        scrollView.setContentHuggingPriority(.defaultLow, for: .vertical)
        let stack = NSStackView(views: [label, scrollView])
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 8
        scrollView.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        stack.setContentHuggingPriority(.defaultLow, for: .vertical)
        return stack
    }

    func testScriptButton() -> NSButton {
        FormFactory.button("Test Workflow", target: self, action: #selector(testScript))
    }

    func saveParametersButton() -> NSButton {
        FormFactory.button("Save Parameters", target: self, action: #selector(saveParameters))
    }

}

@MainActor
extension GestureEditorWindowController {
    @objc func selectGesture(_ sender: NSButton) {
        guard let rawValue = Int(sender.identifier?.rawValue ?? ""),
              let slot = GestureSlot(rawValue: rawValue) else {
            return
        }
        guard configuration.gestures.triggers.indices.contains(slot.index) else { return }
        guard commitVisibleEdits(restartActiveListener: true) else { return }
        let didChangeTrigger = slot != selectedSlot
        if didChangeTrigger {
            resetActionTestState()
        }
        selectedSlot = slot
        selectedAction = ActionSlot(index: 0)
        inspectorMode = .trigger
        loadSelectedRule()
        if didChangeTrigger {
            clearListenerStatusMessage()
        }
    }

    @objc func selectAction(_ sender: NSButton) {
        guard let index = Int(sender.identifier?.rawValue ?? "") else {
            return
        }
        guard commitVisibleEdits(restartActiveListener: true) else { return }
        selectedAction = ActionSlot(index: index)
        inspectorMode = .action
        loadSelectedRule()
    }

    func startListener() {
        guard runtime == nil else { return }

        do {
            try writeVisibleRule()
            try store.save(configuration)
            try startRuntime(configuration)
        } catch {
            updateTriggerEnabledSwitch()
            statusLabel.stringValue = "Listener failed: \(error)"
            logger.error("Listener failed: \(error)")
        }
    }

    func restartListener() {
        runtime?.stop()
        runtime = nil
        updateTriggerEnabledSwitch()
        startListener()
    }

    @objc func saveParameters() {
        guard !isLoadingSelection else { return }
        window?.makeFirstResponder(nil)
        do {
            try writeVisibleRule()
            try store.save(configuration)
            listenerRefreshRequestID = nil
            if runtime != nil {
                try refreshRunningListener()
            }
            updateTriggerEnabledSwitch()
            statusLabel.stringValue = "\(selectedSlot.displayName(in: configuration)) parameters saved."
        } catch {
            updateTriggerEnabledSwitch()
            statusLabel.stringValue = "Save parameters failed: \(error)"
        }
    }

}
