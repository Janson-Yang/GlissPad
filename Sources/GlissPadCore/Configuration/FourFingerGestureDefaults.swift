import Foundation

extension GestureTriggerType {
    func defaultFourFingerTrigger(id: String, ordinal: Int) -> GestureRule {
        .fourFinger(id: id, type: self, rule: defaultFourFingerRule(ordinal: ordinal))
    }

    private func defaultFourFingerRule(ordinal: Int) -> FourFingerGestureRule {
        var rule = FourFingerGestureRule(
            name: "\(displayName) \(ordinal)",
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
        switch self {
        case .fourFingerTouch:
            rule.touch = ThreeFingerTouchOptions(event: .touchStart)
        case .fourFingerTap:
            rule.tap = ThreeFingerTapOptions(tapCount: 1, maximumMovement: 0.06)
        case .fourFingerPress:
            rule.press = FourFingerPressOptions(level: .normal)
        case .fourFingerSwipe:
            rule.swipe = FourFingerGestureRule.defaultSwipeOptions()
        case .thumbThreeFingerScale:
            rule.scale = FourFingerGestureRule.defaultScaleOptions()
        case .fourFingerTipTap:
            rule.tipTap = FourFingerTipTapOptions(tapSide: .auto)
        case .fourFingerDrawing:
            rule.common.maxInitialFingerTimeGapMilliseconds = 350
            rule.drawing = FourFingerGestureRule.defaultDrawingOptions()
        default:
            break
        }
        return rule
    }

    private func commandAction() -> ScriptAction {
        ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript, timeoutSeconds: 5)
    }
}

