import AppKit

@MainActor
extension GestureEditorWindowController {
    func configureScriptModeHelp() {
        scriptModeHelpButton.target = self
        scriptModeHelpButton.action = #selector(showScriptModeHelp(_:))
    }

    @objc func showScriptModeHelp(_ sender: NSButton) {
        scriptModeHelpPopover?.close()
        scriptModeHelpPopover = ScriptModeHelpPopover.show(from: sender)
    }

    func makeScriptActionParameterPanel() -> NSView {
        let panel = GlassPanelView(material: .hudWindow)
        let title = columnTitle("Action Parameters")
        let nameRow = FormFactory.row("Name", actionNameField)
        let scriptTypeRow = FormFactory.row("Script type", scriptTypeControl())
        let scriptLabel = scriptEditorLabel()
        let scriptScrollView = RoundedScriptScrollView()
        let buttonRow = actionParameterButtonRow()
        scriptScrollView.documentView = scriptTextView
        [title, actionListTitleLabel, nameRow, scriptTypeRow, scriptLabel, scriptScrollView, buttonRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            panel.addSubview($0)
        }
        activateScriptPanelConstraints(
            panel: panel,
            title: title,
            nameRow: nameRow,
            scriptTypeRow: scriptTypeRow,
            scriptLabel: scriptLabel,
            scriptScrollView: scriptScrollView,
            buttonRow: buttonRow
        )
        panel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        panel.setContentHuggingPriority(.defaultLow, for: .vertical)
        return panel
    }

    private func scriptTypeControl() -> NSView {
        let row = NSStackView(views: [languagePopup, scriptModeHelpButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        return row
    }

    private func activateScriptPanelConstraints(
        panel: NSView,
        title: NSView,
        nameRow: NSView,
        scriptTypeRow: NSView,
        scriptLabel: NSView,
        scriptScrollView: NSView,
        buttonRow: NSView
    ) {
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            title.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -20),
            title.topAnchor.constraint(equalTo: panel.topAnchor, constant: 18),
            actionListTitleLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            actionListTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -20),
            actionListTitleLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            nameRow.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            nameRow.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -20),
            nameRow.topAnchor.constraint(equalTo: actionListTitleLabel.bottomAnchor, constant: 18),
            scriptTypeRow.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            scriptTypeRow.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -20),
            scriptTypeRow.topAnchor.constraint(equalTo: nameRow.bottomAnchor, constant: 16),
            scriptLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            scriptLabel.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -20),
            scriptLabel.topAnchor.constraint(equalTo: scriptTypeRow.bottomAnchor, constant: 22),
            scriptScrollView.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            scriptScrollView.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),
            scriptScrollView.topAnchor.constraint(equalTo: scriptLabel.bottomAnchor, constant: 8),
            scriptScrollView.bottomAnchor.constraint(equalTo: buttonRow.topAnchor, constant: -14),
            scriptScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360),
            buttonRow.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            buttonRow.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -20),
            buttonRow.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -18),
            panel.widthAnchor.constraint(greaterThanOrEqualToConstant: 260),
            panel.heightAnchor.constraint(greaterThanOrEqualToConstant: 666)
        ])
    }
}
