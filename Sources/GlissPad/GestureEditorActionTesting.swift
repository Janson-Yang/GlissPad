import Foundation
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func resetActionTestState() {
        actionTestSessionID = UUID()
        actionExecutionStates.removeAll()
    }

    func runActionTest(_ actions: [GestureAction]) {
        guard let triggerID = selectedSlot.trigger(in: configuration)?.id else { return }
        let sessionID = UUID()
        let keys = actions.indices.map { ActionTestKey(triggerID: triggerID, actionIndex: $0) }
        actionTestSessionID = sessionID
        actionExecutionStates = actionExecutionStates.filter { $0.key.triggerID != triggerID }
        keys.forEach { actionExecutionStates[$0] = .idle }
        refreshSelectionVisuals()
        statusLabel.stringValue = "Running \(actions.count) action(s)."
        let showsTestHUD = actions.contains { action in
            guard case .testHUD = action else { return false }
            return true
        }

        Task.detached { [actions, keys, showsTestHUD] in
            let runner = ScriptRunner()
            let keyboardRunner = KeyboardShortcutRunner()
            let latencyRunner = LatencyRunner()
            for (index, action) in actions.enumerated() {
                await self.updateActionTest(key: keys[index], state: .running, sessionID: sessionID)
                do {
                    try Self.run(
                        action,
                        scriptRunner: runner,
                        keyboardRunner: keyboardRunner,
                        latencyRunner: latencyRunner
                    )
                    await self.updateActionTest(key: keys[index], state: .succeeded, sessionID: sessionID)
                } catch {
                    await self.finishActionTest(error: error, sessionID: sessionID)
                    return
                }
            }
            await self.finishActionTest(error: nil, sessionID: sessionID, showCompletionHUD: !showsTestHUD)
        }
    }

    nonisolated private static func run(
        _ action: GestureAction,
        scriptRunner: ScriptRunner,
        keyboardRunner: KeyboardShortcutRunner,
        latencyRunner: LatencyRunner
    ) throws {
        switch action {
        case .script(let scriptAction):
            try scriptRunner.run(scriptAction)
        case .keyboardShortcut(let keyboardAction):
            try keyboardRunner.run(keyboardAction)
        case .testHUD(let testHUDAction):
            Task { @MainActor in
                GestureHUD.shared.showStatus(title: testHUDAction.title, detail: testHUDAction.detail, duration: 1.8)
            }
        case .latency(let latencyAction):
            try latencyRunner.run(latencyAction)
        }
    }

    func updateActionTest(key: ActionTestKey, state: ActionExecutionState, sessionID: UUID) {
        guard actionTestSessionID == sessionID else { return }
        actionExecutionStates[key] = state
        refreshSelectionVisuals()
    }

    func finishActionTest(error: Error?, sessionID: UUID, showCompletionHUD: Bool = true) {
        guard actionTestSessionID == sessionID else { return }
        if let error {
            statusLabel.stringValue = "Action failed: \(error)"
            GestureHUD.shared.showStatus(title: "Action failed", detail: "\(error)")
            return
        }
        statusLabel.stringValue = "All actions finished successfully."
        if showCompletionHUD {
            GestureHUD.shared.showStatus(title: "动作执行完成", detail: "所有 action 已按顺序执行")
        }
    }
}
