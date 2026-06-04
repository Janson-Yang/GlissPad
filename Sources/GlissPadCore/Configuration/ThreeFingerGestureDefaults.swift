import Foundation

extension GestureTriggerType {
    func defaultThreeFingerTrigger(id: String, ordinal: Int) -> GestureRule {
        .threeFinger(id: id, type: self, rule: defaultThreeFingerRule(ordinal: ordinal))
    }

    private func defaultThreeFingerRule(ordinal: Int) -> ThreeFingerGestureRule {
        var rule = ThreeFingerGestureRule(
            name: "\(displayName) \(ordinal)",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
        switch self {
        case .threeFingerTouch:
            rule.touch = ThreeFingerTouchOptions(event: .touchStart)
        case .threeFingerTap:
            rule.tap = ThreeFingerTapOptions(tapCount: 1)
        case .threeFingerPress:
            rule.press = ThreeFingerPressOptions(level: .force, triggerTiming: .pressDown)
        case .threeFingerSwipe:
            rule.swipe = ThreeFingerSwipeOptions(direction: .right)
        case .threeFingerTipTap:
            rule.tipTap = ThreeFingerTipTapOptions(tapPosition: .auto)
        case .threeFingerTipSwipe:
            rule.tipSwipe = ThreeFingerTipSwipeOptions(activeFinger: .auto, direction: .up)
        case .thumbTwoFingerScale:
            rule.scale = ThreeFingerScaleOptions(direction: .spreadOut)
        case .threeFingerDrawing:
            rule.drawing = ThreeFingerDrawingOptions()
        default:
            break
        }
        return rule
    }

    private func commandAction() -> ScriptAction {
        ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript, timeoutSeconds: 5)
    }
}
