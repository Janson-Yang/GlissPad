import Foundation

protocol LatencyRunning: Sendable {
    func run(_ action: LatencyAction) throws
}

public final class LatencyRunner: LatencyRunning, Sendable {
    public init() {}

    public func run(_ action: LatencyAction) throws {
        try action.validate(name: "latencyAction")
        Thread.sleep(forTimeInterval: TimeInterval(action.durationMilliseconds) / 1000)
    }
}
