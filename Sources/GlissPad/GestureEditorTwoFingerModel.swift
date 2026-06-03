import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func writeTouchStartRule() throws {
        guard var rule = selectedSlot.touchStartRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.region = try visibleRegion()
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    func writeTipTapRule() throws {
        guard var rule = selectedSlot.tipTapRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.maximumTapMilliseconds = try intValue(tapDurationField, name: "maximum tap duration")
        rule.stationaryMovement = try doubleValue(holdMovementField, name: "stationary movement")
        rule.tapMovement = try doubleValue(tapMovementField, name: "tap movement")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.region = try visibleRegion()
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }

    func writeTransformRule() throws {
        guard var rule = selectedSlot.transformRule(in: configuration) else { return }
        rule.name = try nonEmptyString(triggerNameField, name: "trigger name")
        rule.isEnabled = enabledSwitch.state == .on
        rule.minimumScaleChange = try doubleValue(transformScaleField, name: "minimum scale change")
        rule.minimumRotationDegrees = try doubleValue(transformRotationField, name: "minimum rotation")
        rule.cooldownMilliseconds = try intValue(cooldownField, name: "cooldown")
        rule.region = try visibleRegion()
        if rule.actions.indices.contains(selectedAction.index) {
            rule.actions[selectedAction.index] = try visibleAction()
        }
        selectedSlot.write(rule, to: &configuration)
    }
}
