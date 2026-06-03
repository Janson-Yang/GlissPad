import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    @objc func showAddActionMenu(_ sender: NSButton) {
        actionPickerPopover?.close()
        actionPickerPopover = ActionPickerPopover.show(
            from: sender,
            target: self,
            scriptAction: #selector(addScriptAction(_:)),
            keyboardShortcutAction: #selector(addKeyboardShortcutAction(_:)),
            testHUDAction: #selector(addTestHUDAction(_:)),
            latencyAction: #selector(addLatencyAction(_:))
        )
    }

    @objc func addScriptAction(_ sender: Any) {
        appendAction(.script(ScriptAction(language: .appleScript, script: "return true")))
    }

    @objc func addKeyboardShortcutAction(_ sender: Any) {
        appendAction(.keyboardShortcut(KeyboardShortcutAction(
            mode: .singleKey,
            primaryKey: .a
        )))
    }

    @objc func addTestHUDAction(_ sender: Any) {
        appendAction(.testHUD(TestHUDAction()))
    }

    @objc func addLatencyAction(_ sender: Any) {
        appendAction(.latency(LatencyAction()))
    }

    @objc func deleteSelectedAction() {
        confirmDelete(at: selectedAction.index)
    }

    @objc func confirmDeleteAction(_ sender: NSButton) {
        guard let index = Int(sender.identifier?.rawValue ?? "") else { return }
        confirmDelete(at: index)
    }

    @objc func confirmDeleteActionMenu(_ sender: NSMenuItem) {
        guard let index = sender.representedObject as? Int else { return }
        confirmDelete(at: index)
    }

    func confirmDelete(at index: Int) {
        let actions = selectedSlot.actions(in: configuration)
        guard actions.indices.contains(index) else { return }
        let alert = NSAlert()
        alert.messageText = "Delete this action?"
        alert.informativeText = "This removes \(actions[index].name) from the current trigger."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        if let window {
            alert.beginSheetModal(for: window) { [weak self] response in
                Task { @MainActor in
                    guard response == .alertFirstButtonReturn else { return }
                    self?.deleteAction(at: index)
                }
            }
        } else if alert.runModal() == .alertFirstButtonReturn {
            deleteAction(at: index)
        }
    }

    func deleteAction(at index: Int) {
        do {
            try writeVisibleRule()
            var actions = selectedSlot.actions(in: configuration)
            guard actions.indices.contains(index) else { return }
            actions.remove(at: index)
            selectedAction = ActionSlot(index: max(0, min(index, actions.count - 1)))
            inspectorMode = actions.isEmpty ? .trigger : .action
            selectedSlot.writeActions(actions, to: &configuration)
            try saveCurrentConfiguration(restartActiveListener: true)
            loadSelectedRule()
            statusLabel.stringValue = "Deleted selected action."
        } catch {
            statusLabel.stringValue = "Delete action failed: \(error)"
        }
    }

    @objc func scriptLanguageChanged(_ sender: NSPopUpButton) {
        guard !isLoadingSelection else { return }
        do {
            try writeVisibleRule()
            try saveCurrentConfiguration(restartActiveListener: true)
            updateActionListCopy()
        } catch {
            statusLabel.stringValue = "Action update failed: \(error)"
        }
    }

    @objc func testScript() {
        do {
            try writeVisibleRule()
            try saveCurrentConfiguration(restartActiveListener: true)
            runActionTest(selectedSlot.actions(in: configuration))
        } catch {
            statusLabel.stringValue = "Action failed: \(error)"
        }
    }

    func appendAction(_ action: GestureAction) {
        do {
            actionPickerPopover?.close()
            guard selectedSlot.trigger(in: configuration) != nil else {
                statusLabel.stringValue = "Select or add a trigger first."
                return
            }
            try writeVisibleRule()
            var actions = selectedSlot.actions(in: configuration)
            actions.append(action.defaultNamed(index: actions.count))
            selectedAction = ActionSlot(index: actions.count - 1)
            inspectorMode = .action
            selectedSlot.writeActions(actions, to: &configuration)
            try saveCurrentConfiguration(restartActiveListener: true)
            loadSelectedRule()
            statusLabel.stringValue = "Added action \(actions.count)."
        } catch {
            statusLabel.stringValue = "Add action failed: \(error)"
        }
    }
}
