import AppKit
import GlissPadCore

enum GestureEditorClipboardError: Error, CustomStringConvertible {
    case unsupportedVersion(Int)

    var description: String {
        switch self {
        case .unsupportedVersion(let version):
            return "Unsupported clipboard version \(version)."
        }
    }
}

enum GestureEditorClipboard {
    static let triggerType = NSPasteboard.PasteboardType("local.glisspad.trigger")
    static let actionType = NSPasteboard.PasteboardType("local.glisspad.action")

    private static let version = 1
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func writeTrigger(_ trigger: GestureRule, to pasteboard: NSPasteboard = .general) throws {
        let envelope = TriggerEnvelope(version: version, trigger: trigger)
        pasteboard.clearContents()
        pasteboard.setData(try encoder.encode(envelope), forType: triggerType)
    }

    static func writeAction(_ action: GestureAction, to pasteboard: NSPasteboard = .general) throws {
        let envelope = ActionEnvelope(version: version, action: action)
        pasteboard.clearContents()
        pasteboard.setData(try encoder.encode(envelope), forType: actionType)
    }

    static func readTrigger(from pasteboard: NSPasteboard = .general) throws -> GestureRule? {
        guard let data = pasteboard.data(forType: triggerType) else { return nil }
        let envelope = try decoder.decode(TriggerEnvelope.self, from: data)
        guard envelope.version == version else {
            throw GestureEditorClipboardError.unsupportedVersion(envelope.version)
        }
        try envelope.trigger.validate(name: "clipboard.trigger")
        return envelope.trigger
    }

    static func readAction(from pasteboard: NSPasteboard = .general) throws -> GestureAction? {
        guard let data = pasteboard.data(forType: actionType) else { return nil }
        let envelope = try decoder.decode(ActionEnvelope.self, from: data)
        guard envelope.version == version else {
            throw GestureEditorClipboardError.unsupportedVersion(envelope.version)
        }
        try envelope.action.validate(name: "clipboard.action")
        return envelope.action
    }

    static func hasTrigger(in pasteboard: NSPasteboard = .general) -> Bool {
        (try? readTrigger(from: pasteboard)) != nil
    }

    static func hasAction(in pasteboard: NSPasteboard = .general) -> Bool {
        (try? readAction(from: pasteboard)) != nil
    }
}

private struct TriggerEnvelope: Codable {
    var version: Int
    var trigger: GestureRule
}

private struct ActionEnvelope: Codable {
    var version: Int
    var action: GestureAction
}
