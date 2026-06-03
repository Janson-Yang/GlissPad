import Foundation
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    @discardableResult
    func commitVisibleEdits(restartActiveListener: Bool) -> Bool {
        do {
            let previousConfiguration = configuration
            try writeVisibleRule()
            guard configuration != previousConfiguration else { return true }
            try saveCurrentConfiguration(restartActiveListener: restartActiveListener)
            return true
        } catch {
            statusLabel.stringValue = "Auto-save failed: \(error)"
            updateTriggerEnabledSwitch()
            return false
        }
    }

    func saveCurrentConfiguration(restartActiveListener: Bool) throws {
        try store.save(configuration)
        if restartActiveListener {
            scheduleRunningListenerRefresh()
        }
    }

    func refreshRunningListener() throws {
        guard runtime != nil else { return }
        runtime?.stop()
        runtime = nil
        updateTriggerEnabledSwitch()
        try startRuntime(configuration)
    }

    func startRuntime(_ activeConfiguration: AppConfiguration) throws {
        let runtime = GestureRuntime(
            configuration: activeConfiguration,
            logger: logger,
            notificationHandler: { notification in
                Task { @MainActor in GestureHUD.shared.show(notification) }
            },
            testHUDActionHandler: { action in
                Task { @MainActor in
                    GestureHUD.shared.showStatus(title: action.title, detail: action.detail, duration: 1.8)
                }
            }
        )
        try runtime.start()
        self.runtime = runtime
        clearListenerStatusMessage()
        updateTriggerEnabledSwitch()
        logger.info(listenerStatusLogText())
    }

    func scheduleRunningListenerRefresh() {
        guard runtime != nil else { return }
        let requestID = UUID()
        listenerRefreshRequestID = requestID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            Task { @MainActor in
                guard let self, self.listenerRefreshRequestID == requestID else { return }
                self.listenerRefreshRequestID = nil
                do {
                    try self.refreshRunningListener()
                } catch {
                    self.updateTriggerEnabledSwitch()
                    self.statusLabel.stringValue = "Listener refresh failed: \(error)"
                }
            }
        }
    }
}
