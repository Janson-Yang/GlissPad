import CoreGraphics
import Foundation

final class ClickEventMonitor: @unchecked Sendable {
    private let logger: Logger
    private let lock = NSLock()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var clickGenerationValue: UInt64 = 0
    private var lastClickUptime: TimeInterval?
    private var suppressionWindow = ClickSuppressionWindow()

    init(logger: Logger) {
        self.logger = logger
    }

    var clickGeneration: UInt64 {
        lock.withLock { clickGenerationValue }
    }

    func hasRecentClick(within interval: TimeInterval) -> Bool {
        lock.withLock {
            guard let lastClickUptime else { return false }
            return ProcessInfo.processInfo.systemUptime - lastClickUptime <= interval
        }
    }

    func start() throws {
        guard eventTap == nil else { return }
        let mask = CGEventMask(
            (1 << CGEventType.leftMouseDown.rawValue)
                | (1 << CGEventType.leftMouseUp.rawValue)
        )
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: clickEventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw ClickEventMonitorError.eventTapCreationFailed
        }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        runLoopSource = source
    }

    func stop() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    fileprivate func recordClick() {
        let generation = lock.withLock {
            clickGenerationValue += 1
            lastClickUptime = ProcessInfo.processInfo.systemUptime
            return clickGenerationValue
        }
        logger.debug("Observed system click generation \(generation).")
    }

    func suppressClicks(for interval: TimeInterval) {
        let now = ProcessInfo.processInfo.systemUptime
        lock.withLock {
            suppressionWindow.extend(now: now, duration: interval)
        }
    }

    func clearSuppression() {
        lock.withLock {
            suppressionWindow.clear()
        }
    }

    fileprivate func shouldSuppressClick() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        return lock.withLock {
            suppressionWindow.contains(now: now)
        }
    }

    fileprivate func logSuppressedClick(type: CGEventType) {
        logger.info("Suppressed Force Touch mouse \(type == .leftMouseDown ? "down" : "up") event.")
    }
}

private let clickEventCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<ClickEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    guard type == .leftMouseDown || type == .leftMouseUp else {
        return Unmanaged.passUnretained(event)
    }
    if monitor.shouldSuppressClick() {
        monitor.logSuppressedClick(type: type)
        return nil
    }
    if type == .leftMouseDown {
        monitor.recordClick()
    }
    return Unmanaged.passUnretained(event)
}

struct ClickSuppressionWindow: Equatable, Sendable {
    private var deadline: TimeInterval?

    mutating func extend(now: TimeInterval, duration: TimeInterval) {
        let nextDeadline = now + max(0, duration)
        deadline = max(deadline ?? 0, nextDeadline)
    }

    mutating func contains(now: TimeInterval) -> Bool {
        guard let deadline else { return false }
        if now <= deadline { return true }
        self.deadline = nil
        return false
    }

    mutating func clear() {
        deadline = nil
    }
}

enum ClickEventMonitorError: Error, CustomStringConvertible, Sendable {
    case eventTapCreationFailed

    var description: String {
        switch self {
        case .eventTapCreationFailed:
            return "Could not create a click event tap."
        }
    }
}
