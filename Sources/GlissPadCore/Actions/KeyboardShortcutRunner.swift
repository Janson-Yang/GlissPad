import AppKit
import CoreGraphics
import Foundation

protocol KeyboardShortcutRunning: Sendable {
    func run(_ action: KeyboardShortcutAction) throws
}

public final class KeyboardShortcutRunner: KeyboardShortcutRunning, Sendable {
    private let keyEventSpacing: TimeInterval
    private let scriptTimeout: TimeInterval

    public init(
        keyEventSpacing: TimeInterval = 0.01,
        scriptTimeout: TimeInterval = 2
    ) {
        self.keyEventSpacing = keyEventSpacing
        self.scriptTimeout = scriptTimeout
    }

    public func run(_ action: KeyboardShortcutAction) throws {
        guard AccessibilityPermission.isTrusted else {
            throw ScriptRunnerError.missingAccessibilityPermission
        }
        try action.validate(name: "keyboardShortcutAction")
        let keys = orderedKeys(for: action)

        if let script = KeyboardShortcutAppleScript.script(for: keys) {
            try runSystemEvents(script)
        }
        try runCGEvents(keys, keyHoldDuration: seconds(action.keyHoldMilliseconds))
        sleep(milliseconds: action.postReleaseDelayMilliseconds)
    }

    private func runCGEvents(_ keys: [KeyboardKey], keyHoldDuration: TimeInterval) throws {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            throw KeyboardShortcutRunnerError.eventSourceCreationFailed
        }
        source.localEventsSuppressionInterval = 0

        var activeFlags: CGEventFlags = []
        for (index, key) in keys.enumerated() {
            activeFlags.formUnion(key.modifierFlag)
            try post(key: key, keyDown: true, flags: activeFlags, source: source)
            if index < keys.count - 1 {
                Thread.sleep(forTimeInterval: keyEventSpacing)
            }
        }
        Thread.sleep(forTimeInterval: keyHoldDuration)
        for (index, key) in keys.reversed().enumerated() {
            let flags = activeFlags.subtracting(key.modifierFlag)
            try post(key: key, keyDown: false, flags: flags, source: source)
            activeFlags = flags
            if index < keys.count - 1 {
                Thread.sleep(forTimeInterval: keyEventSpacing)
            }
        }
    }

    private func runSystemEvents(_ script: String) throws {
        let process = Process()
        let errorPipe = Pipe()
        let group = DispatchGroup()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardError = errorPipe
        group.enter()
        process.terminationHandler = { _ in group.leave() }
        try process.run()

        guard group.wait(timeout: .now() + scriptTimeout) == .success else {
            process.terminate()
            throw KeyboardShortcutRunnerError.scriptTimedOut
        }
        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: data, encoding: .utf8) ?? ""
            throw KeyboardShortcutRunnerError.scriptFailed(process.terminationStatus, errorText)
        }
    }

    private func orderedKeys(for action: KeyboardShortcutAction) -> [KeyboardKey] {
        guard action.mode == .keyCombination, let secondaryKey = action.secondaryKey else {
            return [action.primaryKey]
        }
        let keys = [action.primaryKey, secondaryKey]
        return keys.sorted { $0.isModifier && !$1.isModifier }
    }

    private func post(
        key: KeyboardKey,
        keyDown: Bool,
        flags: CGEventFlags,
        source: CGEventSource
    ) throws {
        guard let event = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(key.keyCode),
            keyDown: keyDown
        ) else {
            throw KeyboardShortcutRunnerError.eventCreationFailed(key)
        }
        event.flags = flags
        event.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
        event.setIntegerValueField(.keyboardEventKeyboardType, value: KeyboardShortcutRunner.keyboardTypeANSI)
        if let processID = frontmostProcessID() {
            event.postToPid(processID)
        }
        event.post(tap: .cghidEventTap)
    }

    private static let keyboardTypeANSI: Int64 = 40

    private func seconds(_ milliseconds: Int) -> TimeInterval {
        TimeInterval(milliseconds) / 1_000
    }

    private func sleep(milliseconds: Int) {
        guard milliseconds > 0 else { return }
        Thread.sleep(forTimeInterval: seconds(milliseconds))
    }

    private func frontmostProcessID() -> pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }
}

public enum KeyboardShortcutRunnerError: Error, CustomStringConvertible, Sendable {
    case eventSourceCreationFailed
    case eventCreationFailed(KeyboardKey)
    case scriptFailed(Int32, String)
    case scriptTimedOut

    public var description: String {
        switch self {
        case .eventSourceCreationFailed:
            return "could not create HID keyboard event source"
        case .eventCreationFailed(let key):
            return "could not create keyboard event for \(key.displayName) (\(key.keyCode))"
        case .scriptFailed(let status, let errorText):
            let detail = errorText.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty ? "keyboard shortcut script exited with status \(status)" : detail
        case .scriptTimedOut:
            return "keyboard shortcut script timed out"
        }
    }
}

private extension KeyboardKey {
    var modifierFlag: CGEventFlags {
        switch keyCode {
        case 54, 55:
            return .maskCommand
        case 56, 60:
            return .maskShift
        case 58, 61:
            return .maskAlternate
        case 59, 62:
            return .maskControl
        default: return []
        }
    }
}
