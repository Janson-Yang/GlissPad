import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func configureTriggerEnabledSwitch() {
        enabledSwitch.controlSize = .regular
        enabledSwitch.setAccessibilityLabel("Gesture is Enabled")
        enabledSwitch.setContentHuggingPriority(.required, for: .horizontal)
        enabledSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        updateTriggerEnabledSwitch()
    }

    func updateTriggerEnabledSwitch() {
        let hasTrigger = selectedSlot.trigger(in: configuration) != nil
        enabledSwitch.isHidden = !hasTrigger
        enabledSwitch.isEnabled = hasTrigger
        enabledSwitch.state = selectedSlot.isEnabled(in: configuration) ? .on : .off
        enabledSwitch.toolTip = selectedSlot.isEnabled(in: configuration)
            ? "Trigger is enabled"
            : "Trigger is disabled"
    }

    func clearListenerStatusMessage() {
        guard isListenerStatusMessage(statusLabel.stringValue) else { return }
        statusLabel.stringValue = ""
    }

    func listenerStatusLogText() -> String {
        selectedTriggerIsListening ? "Gesture listener active." : "Gesture listener inactive."
    }

    private var selectedTriggerIsListening: Bool {
        runtime != nil
            && AccessibilityPermission.isTrusted
            && selectedSlot.isEnabled(in: configuration)
    }

    private func isListenerStatusMessage(_ message: String) -> Bool {
        message.hasPrefix("Listener ")
            || message.hasPrefix("Gesture listener ")
    }
}
