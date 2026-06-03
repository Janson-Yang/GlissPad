import AppKit

@MainActor
extension GestureEditorWindowController {
    func makeTriggerConfigPanel() -> NSView {
        triggerParameterPanel(title: "Trackpad Gesture Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Activation pressure", pressureField),
            triggerFormRow("Sustain pressure", sustainPressureField),
            triggerFormRow("Minimum force ms", forceMsField),
            triggerFormRow("Cooldown ms", cooldownField),
            triggerIndented(requiresClickButton),
            makeRegionEditor(labelWidth: triggerFormLabelWidth),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeSwipeConfigPanel() -> NSView {
        triggerParameterPanel(title: "Trackpad Swipe Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Minimum travel", swipeTravelField),
            triggerFormRow("Edge width", swipeEdgeWidthField),
            triggerFormRow("Cooldown ms", cooldownField),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeHoldConfigPanel() -> NSView {
        triggerParameterPanel(title: "Trackpad Hold Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Press type", holdPressKindPopup, controlWidth: 180),
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

    func makeReleaseConfigPanel() -> NSView {
        triggerParameterPanel(title: "Trackpad Release Configuration", views: [
            triggerFormRow("Name", triggerNameField, controlWidth: 180),
            triggerFormRow("Type", activeTriggerLabel, controlWidth: 180),
            triggerFormRow("Fingers before release", releaseFingerCountPopup, controlWidth: 180),
            triggerFormRow("Tolerance time ms", releaseToleranceField),
            triggerFormRow("Cooldown ms", cooldownField),
            inspectorButtonRow(saveParametersButton(), deleteTriggerButton())
        ])
    }

    func makeNoTriggerPanel() -> NSView {
        let label = NSTextField(labelWithString: "Add a trigger to configure trackpad gestures.")
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.cell?.alignment = .left
        return glassPanel(title: "Trackpad Gesture Configuration", views: [label])
    }

    func makeActionParameterPanel() -> NSView {
        let actions = selectedSlot.actions(in: configuration)
        guard actions.indices.contains(selectedAction.index) else {
            return makeNoActionPanel()
        }
        switch actions[selectedAction.index] {
        case .script:
            return makeScriptActionParameterPanel()
        case .keyboardShortcut:
            return makeKeyboardShortcutParameterPanel()
        case .testHUD:
            return makeTestHUDParameterPanel()
        case .latency:
            return makeLatencyParameterPanel()
        }
    }

    private func makeKeyboardShortcutParameterPanel() -> NSView {
        actionParameterPanel(views: [
            actionParameterHeading(),
            FormFactory.row("Name", actionNameField),
            FormFactory.row("Action type", actionTypeLabel),
            FormFactory.row("Mode", keyboardModePopup),
            FormFactory.row("Primary key", primaryKeyField),
            FormFactory.row("Second key", secondaryKeyField),
            inspectorButtonRow(deleteActionButton())
        ])
    }

    private func makeTestHUDParameterPanel() -> NSView {
        actionParameterPanel(views: [
            actionParameterHeading(),
            FormFactory.row("Name", actionNameField),
            FormFactory.row("Action type", actionTypeLabel),
            FormFactory.row("HUD title", testHUDTitleField),
            FormFactory.row("HUD detail", testHUDDetailField),
            inspectorButtonRow(deleteActionButton())
        ])
    }

    private func makeLatencyParameterPanel() -> NSView {
        actionParameterPanel(views: [
            actionParameterHeading(),
            FormFactory.row("Name", actionNameField),
            FormFactory.row("Action type", actionTypeLabel),
            FormFactory.row("Seconds", latencySecondsField),
            FormFactory.row("Milliseconds", latencyMillisecondsField),
            inspectorButtonRow(deleteActionButton())
        ])
    }

    private func makeNoActionPanel() -> NSView {
        actionParameterPanel(views: [
            actionParameterHeading(),
            NSTextField(labelWithString: "Select or add an action.")
        ])
    }

    func scriptEditorLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "Script")
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.cell?.alignment = .left
        return label
    }

    func configureActionListStack() {
        actionListStack.orientation = .vertical
        actionListStack.alignment = .width
        actionListStack.spacing = 0
    }

    func configureTriggerListStack() {
        triggerListStack.orientation = .vertical
        triggerListStack.alignment = .width
        triggerListStack.spacing = 12
    }

    var triggerFormLabelWidth: CGFloat { 150 }

    func triggerParameterPanel(title: String, views: [NSView]) -> NSView {
        let panel = GlassPanelView(material: .hudWindow)
        let heading = columnTitle(title)
        let stack = NSStackView(views: [heading] + views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setContentHuggingPriority(.required, for: .vertical)
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: panel.bottomAnchor)
        ])
        panel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        panel.setContentHuggingPriority(.defaultLow, for: .vertical)
        return panel
    }

    private func actionParameterPanel(views: [NSView]) -> NSView {
        let panel = GlassPanelView(material: .hudWindow)
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: panel.bottomAnchor)
        ])
        panel.widthAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true
        return panel
    }

    private func actionParameterHeading() -> NSView {
        let title = columnTitle("Action Parameters")
        let stack = NSStackView(views: [title, actionListTitleLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        return stack
    }

    func triggerFormRow(
        _ title: String,
        _ control: NSView,
        controlWidth: CGFloat = 120
    ) -> NSView {
        let label = FormFactory.label(title)
        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14
        control.widthAnchor.constraint(lessThanOrEqualToConstant: controlWidth).isActive = true
        return row
    }

    func triggerIndented(_ view: NSView) -> NSView {
        let spacer = NSView()
        spacer.widthAnchor.constraint(equalToConstant: triggerFormLabelWidth).isActive = true
        let row = NSStackView(views: [spacer, view])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14
        return row
    }

    func inspectorButtonRow(_ buttons: NSButton...) -> NSStackView {
        let row = NSStackView(views: buttons)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 16
        row.distribution = .fill
        return row
    }

    func deleteTriggerButton() -> NSButton {
        FormFactory.dangerButton("Delete", target: self, action: #selector(deleteSelectedTrigger))
    }

    private func deleteActionButton() -> NSButton {
        FormFactory.dangerButton("Delete", target: self, action: #selector(deleteSelectedAction))
    }
}
