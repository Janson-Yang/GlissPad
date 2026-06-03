import Foundation

enum KeyboardShortcutAppleScript {
    static func script(for keys: [KeyboardKey]) -> String? {
        if keys.count == 1 {
            return singleKeyScript(for: keys[0])
        }
        return keyCombinationScript(for: keys)
    }

    private static func singleKeyScript(for key: KeyboardKey) -> String? {
        guard modifierName(for: key) == nil else { return nil }
        return "tell application \"System Events\" to key code \(key.keyCode)"
    }

    private static func keyCombinationScript(for keys: [KeyboardKey]) -> String? {
        let modifiers = keys.compactMap(modifierName)
        let regularKeys = keys.filter { modifierName(for: $0) == nil }
        guard regularKeys.count == 1, modifiers.count == keys.count - 1 else { return nil }
        return """
        tell application "System Events" to key code \(regularKeys[0].keyCode) using {\(modifiers.joined(separator: ", "))}
        """
    }

    private static func modifierName(for key: KeyboardKey) -> String? {
        switch key.keyCode {
        case 54, 55:
            return "command down"
        case 56, 60:
            return "shift down"
        case 58, 61:
            return "option down"
        case 59, 62:
            return "control down"
        default:
            return nil
        }
    }
}
