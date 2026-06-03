import ApplicationServices
import CoreGraphics
import Foundation

private enum ProbeTapMode: String {
    case hid
    case session

    var tap: CGEventTapLocation {
        switch self {
        case .hid: return .cghidEventTap
        case .session: return .cgSessionEventTap
        }
    }
}

private final class KeyboardEventLogger {
    private var previousTimestamp: CGEventTimestamp?

    func log(type: CGEventType, event: CGEvent) {
        guard isKeyboardEvent(type) else {
            print("tap event: \(typeName(type))")
            return
        }

        let timestamp = event.timestamp
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let line = [
            timestampSummary(timestamp),
            "type=\(typeName(type))",
            "keyCode=\(keyCode)",
            "key=\(keyName(UInt16(keyCode)))",
            "flags=\(flagSummary(event.flags))",
            "rawFlags=\(hex(event.flags.rawValue))"
        ].joined(separator: "  ")
        print(line)
        fflush(stdout)
    }

    private func timestampSummary(_ timestamp: CGEventTimestamp) -> String {
        defer { previousTimestamp = timestamp }
        guard let previousTimestamp else { return "dt=----.--ms" }
        let delta = Double(timestamp - previousTimestamp) / 1_000_000
        return String(format: "dt=%7.2fms", delta)
    }
}

private let keyboardEventCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let logger = Unmanaged<KeyboardEventLogger>.fromOpaque(userInfo).takeUnretainedValue()
    logger.log(type: type, event: event)
    return Unmanaged.passUnretained(event)
}

private func runProbe(mode: ProbeTapMode) -> Int32 {
    requestAccessibilityPromptIfNeeded()
    let logger = KeyboardEventLogger()
    let loggerPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(logger).toOpaque())
    guard let eventTap = CGEvent.tapCreate(
        tap: mode.tap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: keyboardEventMask(),
        callback: keyboardEventCallback,
        userInfo: loggerPointer
    ) else {
        printEventTapFailure(mode: mode)
        return 1
    }

    printStartup(mode: mode)
    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    CFRunLoopRun()
    return 0
}

private func requestAccessibilityPromptIfNeeded() {
    let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [promptKey: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
}

private func keyboardEventMask() -> CGEventMask {
    (1 << CGEventType.keyDown.rawValue)
        | (1 << CGEventType.keyUp.rawValue)
        | (1 << CGEventType.flagsChanged.rawValue)
}

private func isKeyboardEvent(_ type: CGEventType) -> Bool {
    type == .keyDown || type == .keyUp || type == .flagsChanged
}

private func typeName(_ type: CGEventType) -> String {
    switch type {
    case .keyDown: return "keyDown"
    case .keyUp: return "keyUp"
    case .flagsChanged: return "flagsChanged"
    case .tapDisabledByTimeout: return "tapDisabledByTimeout"
    case .tapDisabledByUserInput: return "tapDisabledByUserInput"
    default: return "type(\(type.rawValue))"
    }
}

private func flagSummary(_ flags: CGEventFlags) -> String {
    var names: [String] = []
    if flags.contains(.maskCommand) { names.append("command") }
    if flags.contains(.maskShift) { names.append("shift") }
    if flags.contains(.maskAlternate) { names.append("option") }
    if flags.contains(.maskControl) { names.append("control") }
    if flags.contains(.maskSecondaryFn) { names.append("fn") }
    if flags.contains(.maskAlphaShift) { names.append("capsLock") }
    if flags.contains(.maskNumericPad) { names.append("numericPad") }
    if flags.contains(.maskHelp) { names.append("help") }
    return names.isEmpty ? "[]" : "[\(names.joined(separator: ","))]"
}

private func keyName(_ keyCode: UInt16) -> String {
    keyNames[keyCode] ?? "Key \(keyCode)"
}

private func hex(_ value: UInt64) -> String {
    "0x" + String(value, radix: 16, uppercase: true)
}

private func printStartup(mode: ProbeTapMode) {
    print("Keyboard Event Probe")
    print("tap=\(mode.rawValue)  events=keyDown,keyUp,flagsChanged")
    print("Press keys or trigger GlissPad workflows. Press Control-C to stop.")
    fflush(stdout)
}

private func printEventTapFailure(mode: ProbeTapMode) {
    fputs(
        """
        Failed to create \(mode.rawValue) keyboard event tap.
        Grant Accessibility and Input Monitoring permission to the terminal app running this tool, then try again.
        You can also retry with --session if --hid is blocked.
        \n
        """,
        stderr
    )
}

private func selectedMode(from arguments: [String]) -> ProbeTapMode? {
    guard let argument = arguments.dropFirst().first else { return .hid }
    switch argument {
    case "--hid": return .hid
    case "--session": return .session
    case "--help", "-h":
        print("Usage: KeyboardEventProbe [--hid|--session]")
        return nil
    default:
        fputs("Unknown option: \(argument)\nUsage: KeyboardEventProbe [--hid|--session]\n", stderr)
        return nil
    }
}

private let keyNames: [UInt16: String] = [
    0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
    8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
    16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
    23: "5", 25: "9", 26: "7", 28: "8", 29: "0", 31: "O", 32: "U",
    34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
    36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape",
    54: "Right Command", 55: "Left Command", 56: "Left Shift",
    57: "Caps Lock", 58: "Left Option", 59: "Left Control",
    60: "Right Shift", 61: "Right Option", 62: "Right Control", 63: "Fn",
    96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
    103: "F11", 105: "F13", 106: "F16", 107: "F14", 109: "F10",
    111: "F12", 113: "F15", 117: "Forward Delete", 118: "F4",
    120: "F2", 122: "F1"
]

if let mode = selectedMode(from: CommandLine.arguments) {
    exit(runProbe(mode: mode))
}
