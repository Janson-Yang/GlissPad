import AppKit
import GlissPadCore
import UniformTypeIdentifiers

@MainActor
extension GestureEditorWindowController {
    func makeConfigurationTransferControls() -> NSView {
        let exportButton = transferButton(
            title: "Export",
            symbolName: "square.and.arrow.up",
            action: #selector(exportConfiguration(_:))
        )
        let importButton = transferButton(
            title: "Import",
            symbolName: "square.and.arrow.down",
            action: #selector(importConfiguration(_:))
        )
        let stack = NSStackView(views: [exportButton, importButton])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        return stack
    }

    @objc func exportConfiguration(_ sender: NSButton) {
        guard commitVisibleEdits(restartActiveListener: true) else { return }
        let panel = NSSavePanel()
        panel.title = "Export GlissPad Configuration"
        panel.nameFieldStringValue = "GlissPad Configuration.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        begin(panel) { [weak self] url in
            self?.finishExport(to: url)
        }
    }

    @objc func importConfiguration(_ sender: NSButton) {
        guard commitVisibleEdits(restartActiveListener: true) else { return }
        let panel = NSOpenPanel()
        panel.title = "Import GlissPad Configuration"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        begin(panel) { [weak self] url in
            self?.finishImport(from: url)
        }
    }

    private func transferButton(title: String, symbolName: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.image = LiquidGlassStyle.symbol(symbolName)
        button.imagePosition = .imageLeading
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 86).isActive = true
        return button
    }

    private func begin(_ panel: NSSavePanel, completion: @escaping (URL) -> Void) {
        if let window {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK, let url = panel.url else { return }
                completion(url)
            }
            return
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        completion(url)
    }

    private func finishExport(to url: URL) {
        do {
            try configuration.validate()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(configuration).write(to: url, options: .atomic)
            statusLabel.stringValue = "Exported configuration."
        } catch {
            presentConfigurationTransferError("Export failed", error: error)
        }
    }

    private func finishImport(from url: URL) {
        do {
            let imported = try AppConfiguration.load(path: url.path)
            let conflicts = ConfigurationImportMerger.conflictingNames(
                current: configuration.gestures.triggers,
                imported: imported.gestures.triggers
            )
            guard !conflicts.isEmpty else {
                try applyImport(imported, resolution: .keepBoth)
                return
            }
            presentImportConflictAlert(imported: imported, conflicts: conflicts)
        } catch {
            presentConfigurationTransferError("Import failed", error: error)
        }
    }
}
