import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func visibleLatencyAction() throws -> GestureAction {
        let seconds = try intValue(latencySecondsField, name: "latency seconds")
        let milliseconds = try intValue(latencyMillisecondsField, name: "latency milliseconds")
        guard seconds >= 0 else { throw GUIValidationError.invalidField("latency seconds") }
        guard (0...999).contains(milliseconds) else {
            throw GUIValidationError.invalidField("latency milliseconds")
        }
        guard seconds <= LatencyAction.maximumDurationMilliseconds / 1_000 else {
            throw GUIValidationError.invalidField("latency duration")
        }
        let durationMilliseconds = seconds * 1_000 + milliseconds
        let durationRange = LatencyAction.minimumDurationMilliseconds...LatencyAction.maximumDurationMilliseconds
        guard durationRange.contains(durationMilliseconds) else {
            throw GUIValidationError.invalidField("latency duration")
        }
        return .latency(LatencyAction(
            name: try nonEmptyString(actionNameField, name: "action name"),
            durationMilliseconds: durationMilliseconds
        ))
    }

    func loadLatencyAction(_ action: LatencyAction) {
        latencySecondsField.stringValue = "\(action.durationMilliseconds / 1_000)"
        latencyMillisecondsField.stringValue = "\(action.durationMilliseconds % 1_000)"
    }
}
