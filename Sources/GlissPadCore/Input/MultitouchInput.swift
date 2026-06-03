import CoreFoundation
import Foundation

public final class MultitouchInput: @unchecked Sendable {
    private let logger: Logger
    private let frameHandler: (TouchFrame) -> Void
    private let clickEventMonitor: ClickEventMonitor
    private let clickSuppressionTracker: ClickSuppressionTracker?
    private let recentClickWindow: TimeInterval = 0.18
    private let clickSuppressionWindow: TimeInterval = 0.55
    private var retainedDeviceList: CFArray?
    private var devices: [MTDeviceRef] = []
    private var running = false

    public init(
        logger: Logger,
        clickSuppressionRule: ClickSuppressionRule? = nil,
        frameHandler: @escaping (TouchFrame) -> Void
    ) {
        self.logger = logger
        self.clickSuppressionTracker = clickSuppressionRule.map(ClickSuppressionTracker.init)
        self.frameHandler = frameHandler
        clickEventMonitor = ClickEventMonitor(logger: logger)
    }

    deinit {
        stop()
    }

    public func start() throws {
        guard !running else { return }
        startClickEventMonitorIfPossible()
        do {
            try startMultitouchDevices()
        } catch {
            clickEventMonitor.stop()
            throw error
        }
        running = true
    }

    private func startClickEventMonitorIfPossible() {
        do {
            try clickEventMonitor.start()
        } catch {
            logger.error("Click event tap unavailable; using pressure-only click recognition: \(error)")
        }
    }

    private func startMultitouchDevices() throws {
        guard let unmanagedList = MTDeviceCreateList() else { throw MultitouchError.noDeviceList }

        let deviceList = unmanagedList.takeRetainedValue()
        retainedDeviceList = deviceList
        devices = extractDevices(from: deviceList)
        guard !devices.isEmpty else { throw MultitouchError.noDevices }

        var startedDevices: [MTDeviceRef] = []
        for device in devices {
            MTRegisterContactFrameCallbackWithRefcon(device, contactFrameCallback, refcon)
            let status = MTDeviceStart(device, 0)
            guard status == 0 else {
                MTUnregisterContactFrameCallback(device, contactFrameCallback)
                startedDevices.forEach {
                    MTUnregisterContactFrameCallback($0, contactFrameCallback)
                    _ = MTDeviceStop($0)
                }
                throw MultitouchError.startFailed(status)
            }
            startedDevices.append(device)
            logger.debug("Started MT device \(device) with status \(status).")
        }
    }

    public func stop() {
        guard running else { return }
        clickEventMonitor.stop()
        for device in devices {
            MTUnregisterContactFrameCallback(device, contactFrameCallback)
        }
        Thread.sleep(forTimeInterval: 0.05)
        devices.forEach { _ = MTDeviceStop($0) }
        devices.removeAll()
        retainedDeviceList = nil
        running = false
    }

    private var refcon: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }

    private func extractDevices(from deviceList: CFArray) -> [MTDeviceRef] {
        let count = CFArrayGetCount(deviceList)
        return (0..<count).compactMap { index in
            guard let value = CFArrayGetValueAtIndex(deviceList, index) else { return nil }
            return UnsafeMutableRawPointer(mutating: value)
        }
    }

    fileprivate func handle(touches: UnsafeMutableRawPointer?, count: Int32, timestamp: Double, frame: Int32) {
        guard let touches, count >= 0 else { return }
        let buffer = touches.bindMemory(to: MTTouch.self, capacity: Int(count))
        let points = (0..<Int(count)).map { TouchPoint(touch: buffer[$0]) }
        updateClickSuppression(touches: points, timestamp: timestamp)
        frameHandler(TouchFrame(
            touches: points,
            timestamp: timestamp,
            frameNumber: Int(frame),
            clickGeneration: clickEventMonitor.clickGeneration,
            hasRecentClick: clickEventMonitor.hasRecentClick(within: recentClickWindow)
        ))
    }

    private func updateClickSuppression(touches: [TouchPoint], timestamp: TimeInterval) {
        guard let decision = clickSuppressionTracker?.update(touches: touches, timestamp: timestamp) else {
            return
        }
        switch decision {
        case .suppress:
            clickEventMonitor.suppressClicks(for: clickSuppressionWindow)
        case .clear:
            clickEventMonitor.clearSuppression()
        case .none:
            break
        }
    }
}

public struct ClickSuppressionRule: Equatable, Sendable {
    let fingerCount: Int
    let minimumPressure: Double
    let sustainingPressure: Double
    let minimumForceMilliseconds: Int
    let maximumMovement: Double

    public init(
        fingerCount: Int,
        minimumPressure: Double,
        sustainingPressure: Double,
        minimumForceMilliseconds: Int,
        maximumMovement: Double
    ) {
        self.fingerCount = fingerCount
        self.minimumPressure = minimumPressure
        self.sustainingPressure = sustainingPressure
        self.minimumForceMilliseconds = minimumForceMilliseconds
        self.maximumMovement = maximumMovement
    }
}

private let contactFrameCallback: MTFrameCallback = { _, touches, count, timestamp, frame, refcon in
    guard let refcon else { return }
    let input = Unmanaged<MultitouchInput>.fromOpaque(refcon).takeUnretainedValue()
    input.handle(touches: touches, count: count, timestamp: timestamp, frame: frame)
}

private extension TouchPoint {
    init(touch: MTTouch) {
        let position = touch.normalizedVector.position
        self.init(
            id: Int(touch.pathIndex),
            state: TouchState(rawValue: touch.state),
            position: NormalizedPoint(x: Double(position.x), y: Double(position.y)),
            pressure: Double(touch.zTotal),
            size: Double(touch.zTotal)
        )
    }
}

enum MultitouchError: Error, CustomStringConvertible, Sendable {
    case noDeviceList
    case noDevices
    case startFailed(Int32)

    var description: String {
        switch self {
        case .noDeviceList:
            return "Could not create a MultitouchSupport device list."
        case .noDevices:
            return "No multitouch devices were found."
        case .startFailed(let status):
            return "MultitouchSupport failed to start a device with status \(status)."
        }
    }
}
