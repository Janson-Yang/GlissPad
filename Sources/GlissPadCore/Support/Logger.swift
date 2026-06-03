import Foundation

public final class Logger: @unchecked Sendable {
    private let debugEnabled: Bool
    private let logFileURL: URL?
    private let lock = NSLock()

    public init(debugEnabled: Bool, logFileURL: URL? = nil) {
        self.debugEnabled = debugEnabled
        self.logFileURL = logFileURL
    }

    public func info(_ message: String) {
        write("info", message)
    }

    public func debug(_ message: String) {
        guard debugEnabled else { return }
        write("debug", message)
    }

    public func error(_ message: String) {
        write("error", message)
    }

    private func write(_ level: String, _ message: String) {
        lock.withLock {
            let line = "[\(level)] \(message)\n"
            let data = Data(line.utf8)
            FileHandle.standardError.write(data)
            writeToLogFile(data)
        }
    }

    private func writeToLogFile(_ data: Data) {
        guard let logFileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: logFileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: logFileURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.close()
        } catch {
            FileHandle.standardError.write(Data("[error] Could not write log file: \(error)\n".utf8))
        }
    }
}
