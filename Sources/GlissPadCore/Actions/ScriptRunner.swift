import Foundation

protocol ScriptRunning: Sendable {
    func run(_ action: ScriptAction) throws
}

public final class ScriptRunner: ScriptRunning, Sendable {
    public init() {}

    public func run(_ action: ScriptAction) throws {
        try action.validate(name: "scriptAction")
        switch action.language {
        case .shell:
            try runShell(action)
        case .appleScript:
            try runAppleScript(action.script)
        }
    }

    private func runShell(_ action: ScriptAction) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: action.language.executablePath)
        process.arguments = action.language.arguments(for: action.script)

        let errorPipe = Pipe()
        process.standardError = errorPipe
        let group = DispatchGroup()
        group.enter()
        process.terminationHandler = { _ in group.leave() }
        try process.run()

        let finished = wait(for: group, timeout: action.timeoutSeconds)
        if !finished {
            process.terminate()
            throw ScriptRunnerError.timedOut(action.timeoutSeconds)
        }

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: data, encoding: .utf8) ?? ""
            throw ScriptRunnerError.failed(process.terminationStatus, errorText)
        }
    }

    private func runAppleScript(_ script: String) throws {
        if script.contains("System Events"), !AccessibilityPermission.isTrusted {
            throw ScriptRunnerError.missingAccessibilityPermission
        }
        guard let appleScript = NSAppleScript(source: script) else {
            throw ScriptRunnerError.failed(1, "AppleScript could not be created.")
        }
        var errorInfo: NSDictionary?
        _ = appleScript.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw ScriptRunnerError.failed(1, formatAppleScriptError(errorInfo))
        }
    }

    private func wait(for group: DispatchGroup, timeout: TimeInterval) -> Bool {
        return group.wait(timeout: .now() + timeout) == .success
    }

    private func formatAppleScriptError(_ errorInfo: NSDictionary) -> String {
        let message = errorInfo["NSAppleScriptErrorMessage"] as? String
        let number = errorInfo["NSAppleScriptErrorNumber"] as? NSNumber
        if let message, let number {
            return "\(message) (\(number.intValue))"
        }
        return "\(errorInfo)"
    }
}

public enum ScriptRunnerError: Error, CustomStringConvertible, Sendable {
    case failed(Int32, String)
    case missingAccessibilityPermission
    case timedOut(TimeInterval)

    public var description: String {
        switch self {
        case .failed(let status, let errorText):
            let detail = errorText.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty ? "script exited with status \(status)" : detail
        case .missingAccessibilityPermission:
            return "GlissPad needs Accessibility permission to run this script."
        case .timedOut(let timeout):
            return "script timed out after \(timeout) seconds"
        }
    }
}
