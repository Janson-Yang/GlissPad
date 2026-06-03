import Foundation

public final class GestureRuntime {
    private let input: MultitouchInput

    public init(
        configuration: AppConfiguration,
        logger: Logger,
        notificationHandler: GestureNotificationHandler? = nil,
        testHUDActionHandler: TestHUDActionHandler? = nil
    ) {
        let actionExecutor = ActionExecutor(testHUDActionHandler: testHUDActionHandler, logger: logger)
        let pipeline = GesturePipeline(
            recognizer: GestureRecognizer(configuration: configuration.gestures),
            actionRunner: actionExecutor,
            logger: logger,
            notificationHandler: notificationHandler
        )
        input = MultitouchInput(
            logger: logger,
            clickSuppressionRule: Self.clickSuppressionRule(for: configuration),
            frameHandler: pipeline.handle
        )
    }

    public func start() throws {
        try input.start()
    }

    public func stop() {
        input.stop()
    }

    static func clickSuppressionRule(for configuration: AppConfiguration) -> ClickSuppressionRule? {
        let rules = configuration.gestures.triggers
            .compactMap(threeFingerPressRule)
            .filter(\.isEnabled)
        guard let first = rules.first else { return nil }
        return ClickSuppressionRule(
            fingerCount: first.fingerCount,
            minimumPressure: rules.map(\.minimumPressure).min() ?? first.minimumPressure,
            sustainingPressure: rules.map(\.sustainingPressure).min() ?? first.sustainingPressure,
            minimumForceMilliseconds: rules.map(\.minimumForceMilliseconds).min()
                ?? first.minimumForceMilliseconds,
            maximumMovement: rules.map(\.maximumMovement).max() ?? first.maximumMovement
        )
    }

    private static func threeFingerPressRule(_ trigger: GestureRule) -> PressGestureRule? {
        guard case .press(_, .threeFingerForcePress, let rule) = trigger else { return nil }
        return rule
    }
}
