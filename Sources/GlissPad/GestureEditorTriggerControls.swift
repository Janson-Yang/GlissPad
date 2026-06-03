import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    @objc func showAddTriggerMenu(_ sender: NSButton) {
        triggerPickerPopover?.close()
        triggerPickerPopover = TriggerPickerPopover.show(
            from: sender,
            target: self,
            action: #selector(addTriggerFromMenu(_:))
        )
    }

    @objc func addTriggerFromMenu(_ sender: NSButton) {
        guard let type = GestureTriggerType(rawValue: sender.identifier?.rawValue ?? "") else {
            return
        }
        appendTrigger(type)
    }

    func appendTrigger(_ type: GestureTriggerType) {
        do {
            triggerPickerPopover?.close()
            guard commitVisibleEdits(restartActiveListener: true) else { return }
            let trigger = type.defaultTrigger(
                id: UUID().uuidString,
                ordinal: nextTriggerOrdinal(for: type)
            ).replacingActions([])
            configuration.gestures.triggers.append(trigger)
            selectedSlot = GestureSlot(index: configuration.gestures.triggers.count - 1)
            selectedAction = ActionSlot(index: 0)
            inspectorMode = .trigger
            try saveCurrentConfiguration(restartActiveListener: true)
            rebuildTriggerList()
            loadSelectedRule()
            statusLabel.stringValue = "Added \(type.displayName)."
        } catch {
            statusLabel.stringValue = "Add trigger failed: \(error)"
        }
    }

    @objc func confirmDeleteTrigger(_ sender: NSButton) {
        guard let index = Int(sender.identifier?.rawValue ?? ""),
              configuration.gestures.triggers.indices.contains(index) else {
            return
        }
        confirmDeleteTrigger(at: index)
    }

    @objc func confirmDeleteTriggerMenu(_ sender: NSMenuItem) {
        guard let index = sender.representedObject as? Int else { return }
        confirmDeleteTrigger(at: index)
    }

    @objc func deleteSelectedTrigger() {
        confirmDeleteTrigger(at: selectedSlot.index)
    }

    func confirmDeleteTrigger(at index: Int) {
        guard configuration.gestures.triggers.indices.contains(index) else { return }
        let alert = NSAlert()
        alert.messageText = "Delete this trigger?"
        alert.informativeText = "This removes \(configuration.gestures.triggers[index].name) and its actions."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        if let window {
            alert.beginSheetModal(for: window) { [weak self] response in
                Task { @MainActor in
                    guard response == .alertFirstButtonReturn else { return }
                    self?.deleteTrigger(at: index)
                }
            }
            return
        }
        if alert.runModal() == .alertFirstButtonReturn {
            deleteTrigger(at: index)
        }
    }

    func deleteTrigger(at index: Int) {
        do {
            guard configuration.gestures.triggers.indices.contains(index) else { return }
            guard commitVisibleEdits(restartActiveListener: true) else { return }
            let name = configuration.gestures.triggers[index].name
            configuration.gestures.triggers.remove(at: index)
            selectTriggerAfterDeleting(index)
            inspectorMode = .trigger
            selectedAction = ActionSlot(index: 0)
            try saveCurrentConfiguration(restartActiveListener: true)
            rebuildTriggerList()
            loadSelectedRule()
            statusLabel.stringValue = "Deleted \(name)."
        } catch {
            statusLabel.stringValue = "Delete trigger failed: \(error)"
        }
    }

    private func nextTriggerOrdinal(for type: GestureTriggerType) -> Int {
        configuration.gestures.triggers.filter { $0.type == type }.count + 1
    }

    private func selectTriggerAfterDeleting(_ index: Int) {
        guard !configuration.gestures.triggers.isEmpty else {
            selectedSlot = GestureSlot(index: 0)
            return
        }
        if selectedSlot.index == index {
            selectedSlot = GestureSlot(index: min(index, configuration.gestures.triggers.count - 1))
        } else if selectedSlot.index > index {
            selectedSlot = GestureSlot(index: selectedSlot.index - 1)
        }
    }
}
