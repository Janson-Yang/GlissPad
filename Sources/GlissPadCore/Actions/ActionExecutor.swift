import Foundation

protocol ActionRunning: Sendable {
    func run(_ actions: [GestureAction])
}

public typealias TestHUDActionHandler = @Sendable (TestHUDAction) -> Void

public final class ActionExecutor: ActionRunning, @unchecked Sendable {
    private let scriptRunner: ScriptRunning
    private let keyboardShortcutRunner: KeyboardShortcutRunning
    private let latencyRunner: LatencyRunning
    private let testHUDActionHandler: TestHUDActionHandler?
    private let logger: Logger
    private let queue = DispatchQueue(label: "glisspad.actions")

    init(
        scriptRunner: ScriptRunning = ScriptRunner(),
        keyboardShortcutRunner: KeyboardShortcutRunning = KeyboardShortcutRunner(),
        latencyRunner: LatencyRunning = LatencyRunner(),
        testHUDActionHandler: TestHUDActionHandler? = nil,
        logger: Logger
    ) {
        self.scriptRunner = scriptRunner
        self.keyboardShortcutRunner = keyboardShortcutRunner
        self.latencyRunner = latencyRunner
        self.testHUDActionHandler = testHUDActionHandler
        self.logger = logger
    }

    func run(_ actions: [GestureAction]) {
        queue.async { [scriptRunner, keyboardShortcutRunner, latencyRunner, testHUDActionHandler, logger] in
            for (index, action) in actions.enumerated() {
                do {
                    try Self.run(action, scriptRunner, keyboardShortcutRunner, latencyRunner, testHUDActionHandler)
                    logger.info("Action \(index + 1) finished successfully.")
                } catch {
                    logger.error("Action \(index + 1) failed: \(error)")
                    return
                }
            }
        }
    }

    private static func run(
        _ action: GestureAction,
        _ scriptRunner: ScriptRunning,
        _ keyboardShortcutRunner: KeyboardShortcutRunning,
        _ latencyRunner: LatencyRunning,
        _ testHUDActionHandler: TestHUDActionHandler?
    ) throws {
        switch action {
        case .script(let scriptAction):
            try scriptRunner.run(scriptAction)
        case .keyboardShortcut(let keyboardShortcutAction):
            try keyboardShortcutRunner.run(keyboardShortcutAction)
        case .testHUD(let testHUDAction):
            testHUDActionHandler?(testHUDAction)
        case .latency(let latencyAction):
            try latencyRunner.run(latencyAction)
        }
    }
}
