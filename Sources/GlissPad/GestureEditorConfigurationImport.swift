import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func presentImportConflictAlert(imported: AppConfiguration, conflicts: [String]) {
        let alert = NSAlert()
        alert.messageText = "Resolve import conflicts"
        alert.informativeText = conflictMessage(for: conflicts)
        alert.addButton(withTitle: "Keep Both")
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Skip")
        alert.addButton(withTitle: "Cancel")
        if let window {
            alert.beginSheetModal(for: window) { [weak self] response in
                Task { @MainActor in
                    self?.handleImportConflictResponse(response, imported: imported)
                }
            }
            return
        }
        handleImportConflictResponse(alert.runModal(), imported: imported)
    }

    func applyImport(
        _ imported: AppConfiguration,
        resolution: ConfigurationImportConflictResolution
    ) throws {
        let result = ConfigurationImportMerger.merge(
            current: configuration.gestures.triggers,
            imported: imported.gestures.triggers,
            resolution: resolution
        )
        guard result.appliedCount > 0 else {
            statusLabel.stringValue = importStatus(for: result)
            return
        }
        try saveImportedConfiguration(result)
        statusLabel.stringValue = importStatus(for: result)
    }

    func presentConfigurationTransferError(_ title: String, error: Error) {
        statusLabel.stringValue = "\(title): \(error)"
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = "\(error)"
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    private func handleImportConflictResponse(_ response: NSApplication.ModalResponse, imported: AppConfiguration) {
        guard let resolution = importResolution(for: response) else { return }
        do {
            try applyImport(imported, resolution: resolution)
        } catch {
            presentConfigurationTransferError("Import failed", error: error)
        }
    }

    private func saveImportedConfiguration(_ result: ConfigurationImportResult) throws {
        let previousConfiguration = configuration
        let previousSlot = selectedSlot
        var updatedConfiguration = configuration
        updatedConfiguration.gestures.triggers = result.triggers
        try updatedConfiguration.validate()
        configuration = updatedConfiguration
        selectedSlot = GestureSlot(index: result.selectedIndex ?? selectedSlot.index)
        selectedAction = ActionSlot(index: 0)
        inspectorMode = .trigger
        resetActionTestState()
        do {
            try saveCurrentConfiguration(restartActiveListener: true)
        } catch {
            configuration = previousConfiguration
            selectedSlot = previousSlot
            throw error
        }
        rebuildTriggerList()
        loadSelectedRule()
    }

    private func importResolution(
        for response: NSApplication.ModalResponse
    ) -> ConfigurationImportConflictResolution? {
        switch response {
        case .alertFirstButtonReturn:
            return .keepBoth
        case .alertSecondButtonReturn:
            return .replace
        case .alertThirdButtonReturn:
            return .skip
        default:
            return nil
        }
    }

    private func conflictMessage(for conflicts: [String]) -> String {
        let listedNames = conflicts.prefix(5).joined(separator: ", ")
        let extraCount = max(0, conflicts.count - 5)
        let suffix = extraCount == 0 ? "" : ", and \(extraCount) more"
        return "\(conflicts.count) imported trigger name(s) already exist: \(listedNames)\(suffix)."
    }

    private func importStatus(for result: ConfigurationImportResult) -> String {
        if result.appliedCount == 0 {
            return result.skippedCount == 0 ? "No triggers to import." : "Skipped \(result.skippedCount) trigger(s)."
        }
        let renamed = result.renamedCount == 0 ? "" : " Renamed \(result.renamedCount)."
        let skipped = result.skippedCount == 0 ? "" : " Skipped \(result.skippedCount)."
        return "Imported \(result.addedCount), replaced \(result.replacedCount).\(renamed)\(skipped)"
    }
}
