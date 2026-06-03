import ApplicationServices
import Foundation

public enum AccessibilityPermission {
    public static func requestIfNeeded(prompt: Bool, logger: Logger) {
        let optionKey = "AXTrustedCheckOptionPrompt"
        let options = [optionKey: prompt] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        if trusted {
            logger.debug("Accessibility permission is already trusted.")
        } else {
            logger.info("Accessibility permission is needed for global events and key emission.")
        }
    }

    public static var isTrusted: Bool {
        AXIsProcessTrusted()
    }
}
