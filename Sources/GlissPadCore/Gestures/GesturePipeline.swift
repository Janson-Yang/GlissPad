import Foundation

final class GesturePipeline {
    private let recognizer: GestureRecognizer
    private let actionRunner: ActionRunning
    private let logger: Logger
    private let notificationHandler: GestureNotificationHandler?
    private let queue = DispatchQueue(label: "glisspad.gesture-pipeline")

    init(
        recognizer: GestureRecognizer,
        actionRunner: ActionRunning,
        logger: Logger,
        notificationHandler: GestureNotificationHandler? = nil
    ) {
        self.recognizer = recognizer
        self.actionRunner = actionRunner
        self.logger = logger
        self.notificationHandler = notificationHandler
    }

    func handle(_ frame: TouchFrame) {
        queue.async { [recognizer, actionRunner, logger, notificationHandler] in
            logger.debug(Self.describe(frame))
            recognizer.process(frame).forEach { gesture in
                logger.info("Recognized \(gesture.kind.rawValue); running \(gesture.actions.count) action(s).")
                notificationHandler?(GestureNotification(gesture: gesture))
                actionRunner.run(gesture.actions)
            }
        }
    }

    private static func describe(_ frame: TouchFrame) -> String {
        let active = frame.activeTouches
        let pressure = active.map(\.pressure).max() ?? 0
        let positions = active.map { point in
            String(format: "%.2f,%.2f", point.position.x, point.position.y)
        }.joined(separator: " ")
        return String(
            format: "frame=%d touches=%d pressure=%.3f positions=[%@]",
            frame.frameNumber,
            active.count,
            pressure,
            positions
        )
    }
}

public typealias GestureNotificationHandler = @Sendable (GestureNotification) -> Void

public struct GestureNotification: Equatable, Sendable {
    public let kind: String
    public let actionSummary: String
    public let timestamp: TimeInterval

    init(gesture: RecognizedGesture) {
        kind = gesture.kind.rawValue
        actionSummary = "\(gesture.actions.count) action(s)"
        timestamp = gesture.frame.timestamp
    }
}
