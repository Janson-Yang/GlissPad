import AppKit

@MainActor
extension GestureEditorWindowController {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !allowsWindowCloseForTermination else { return true }
        commitVisibleEdits(restartActiveListener: true)
        sender.orderOut(nil)
        return false
    }

    func windowWillClose(_ notification: Notification) {
        guard allowsWindowCloseForTermination else { return }
        listenerRefreshRequestID = nil
        stopRuntime()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let window else { return }
        window.minSize = ScreenLayoutMetrics.current(for: window).minimumWindowSize
    }

    func prepareForTermination() {
        allowsWindowCloseForTermination = true
        listenerRefreshRequestID = nil
        commitVisibleEdits(restartActiveListener: false)
        stopRuntime()
    }

    private func stopRuntime() {
        runtime?.stop()
        runtime = nil
        updateTriggerEnabledSwitch()
    }
}
