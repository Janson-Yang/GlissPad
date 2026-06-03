import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    @objc func copyTriggerMenu(_ sender: NSMenuItem) {
        guard let index = sender.representedObject as? Int else { return }
        copyTrigger(at: index)
    }

    @objc func pasteTriggerMenu(_ sender: NSMenuItem) {
        pasteTrigger(after: sender.representedObject as? Int)
    }

    @objc func copyActionMenu(_ sender: NSMenuItem) {
        guard let index = sender.representedObject as? Int else { return }
        copyAction(at: index)
    }

    @objc func pasteActionMenu(_ sender: NSMenuItem) {
        pasteAction(after: sender.representedObject as? Int)
    }

    func copyTrigger(at index: Int) {
        do {
            guard commitVisibleEdits(restartActiveListener: true) else { return }
            guard configuration.gestures.triggers.indices.contains(index) else { return }
            let trigger = configuration.gestures.triggers[index]
            try GestureEditorClipboard.writeTrigger(trigger)
            statusLabel.stringValue = "Copied trigger \(trigger.name)."
        } catch {
            statusLabel.stringValue = "Copy trigger failed: \(error)"
        }
    }

    func pasteTrigger(after index: Int?) {
        do {
            guard commitVisibleEdits(restartActiveListener: true) else { return }
            guard let copiedTrigger = try GestureEditorClipboard.readTrigger() else {
                statusLabel.stringValue = "No trigger is available to paste."
                return
            }
            let trigger = pastedTrigger(from: copiedTrigger)
            let insertIndex = insertionIndex(after: index, count: configuration.gestures.triggers.count)
            configuration.gestures.triggers.insert(trigger, at: insertIndex)
            selectedSlot = GestureSlot(index: insertIndex)
            selectedAction = ActionSlot(index: 0)
            inspectorMode = .trigger
            try saveCurrentConfiguration(restartActiveListener: true)
            rebuildTriggerList()
            loadSelectedRule()
            statusLabel.stringValue = "Pasted trigger \(trigger.name)."
        } catch {
            statusLabel.stringValue = "Paste trigger failed: \(error)"
        }
    }

    func copyAction(at index: Int) {
        do {
            guard commitVisibleEdits(restartActiveListener: true) else { return }
            let actions = selectedSlot.actions(in: configuration)
            guard actions.indices.contains(index) else { return }
            try GestureEditorClipboard.writeAction(actions[index])
            statusLabel.stringValue = "Copied action \(actions[index].name)."
        } catch {
            statusLabel.stringValue = "Copy action failed: \(error)"
        }
    }

    func pasteAction(after index: Int?) {
        do {
            guard selectedSlot.trigger(in: configuration) != nil else {
                statusLabel.stringValue = "Select or add a trigger first."
                return
            }
            try writeVisibleRule()
            guard let copiedAction = try GestureEditorClipboard.readAction() else {
                statusLabel.stringValue = "No action is available to paste."
                return
            }
            var actions = selectedSlot.actions(in: configuration)
            let action = pastedAction(from: copiedAction, existingActions: actions)
            let insertIndex = insertionIndex(after: index, count: actions.count)
            actions.insert(action, at: insertIndex)
            selectedAction = ActionSlot(index: insertIndex)
            inspectorMode = .action
            selectedSlot.writeActions(actions, to: &configuration)
            try saveCurrentConfiguration(restartActiveListener: true)
            loadSelectedRule()
            statusLabel.stringValue = "Pasted action \(action.name)."
        } catch {
            statusLabel.stringValue = "Paste action failed: \(error)"
        }
    }

    private func pastedTrigger(from trigger: GestureRule) -> GestureRule {
        let existingNames = Set(configuration.gestures.triggers.map(\.name))
        return trigger
            .replacingIdentifier(UUID().uuidString)
            .replacingName(uniqueCopyName(for: trigger.name, existingNames: existingNames))
    }

    private func pastedAction(
        from action: GestureAction,
        existingActions: [GestureAction]
    ) -> GestureAction {
        let existingNames = Set(existingActions.map(\.name))
        return action.replacingName(uniqueCopyName(for: action.name, existingNames: existingNames))
    }

    private func uniqueCopyName(for name: String, existingNames: Set<String>) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmedName.isEmpty ? "Copy" : "\(trimmedName) Copy"
        guard existingNames.contains(base) else { return base }
        for suffix in 2... {
            let candidate = "\(base) \(suffix)"
            if !existingNames.contains(candidate) { return candidate }
        }
        return base
    }

    private func insertionIndex(after index: Int?, count: Int) -> Int {
        guard let index else { return count }
        return max(0, min(index + 1, count))
    }
}
