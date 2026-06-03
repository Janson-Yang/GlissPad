import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func writeShapeRule() throws {
        guard var rule = selectedSlot.shapeRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.cornerTolerance = try doubleValue(pathToleranceField, name: "corner tolerance")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }
}
