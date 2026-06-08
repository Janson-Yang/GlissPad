import Foundation

extension GestureTriggerType {
    func defaultFiveAndMoreFingerTrigger(id: String, ordinal: Int) -> GestureRule {
        .fiveAndMoreFinger(id: id, type: self, rule: defaultFiveAndMoreFingerRule(ordinal: ordinal))
    }

    private func defaultFiveAndMoreFingerRule(ordinal: Int) -> FiveAndMoreFingerGestureRule {
        var rule = FiveAndMoreFingerGestureRule(
            name: "\(displayName) \(ordinal)",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
        switch self {
        case .fiveFingerTouch:
            rule.touch = FiveFingerTouchOptions(event: .touchStart)
        case .fiveFingerTap:
            rule.tap = FiveAndMoreFingerGestureRule.defaultTapOptions()
        case .fiveFingerPress:
            rule.press = FourFingerPressOptions(level: .normal)
        case .thumbFourFingerScale:
            rule.scale = FiveAndMoreFingerGestureRule.defaultScaleOptions()
        case .fiveFingerSwipe:
            rule.swipe = FiveAndMoreFingerGestureRule.defaultSwipeOptions()
        case .fiveFingerDrawing:
            rule.common.maxInitialFingerTimeGapMilliseconds = 350
            rule.drawing = FiveAndMoreFingerGestureRule.defaultDrawingOptions()
        case .wholeHandTap:
            rule.wholeHandTap = WholeHandTapOptions()
        default:
            break
        }
        return rule
    }

    private func commandAction() -> ScriptAction {
        ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript, timeoutSeconds: 5)
    }
}
