import Foundation

public extension GestureTriggerType {
    func defaultTrigger(id: String, ordinal: Int) -> GestureRule {
        switch self {
        case .oneFingerTouchStart:
            return .oneFinger(id: id, type: self, rule: defaultOneFingerRule(ordinal: ordinal))
        case .oneFingerLongPress:
            return .hold(id: id, type: self, rule: defaultOneFingerLongPressRule(ordinal: ordinal))
        case .oneFingerCircle:
            return .circle(id: id, type: self, rule: defaultCircleRule(ordinal: ordinal))
        case .oneFingerSquare:
            return .shape(id: id, type: self, rule: defaultShapeRule(.square, ordinal: ordinal))
        case .oneFingerTriangle:
            return .shape(id: id, type: self, rule: defaultShapeRule(.triangle, ordinal: ordinal))
        case .oneFingerCornerClick:
            return .cornerClick(id: id, type: self, rule: defaultCornerClickRule(ordinal: ordinal))
        case .oneFingerTap:
            return .tap(id: id, type: self, rule: defaultTapRule(ordinal: ordinal, tapCount: 1))
        case .oneFingerDoubleTap:
            return .tap(id: id, type: self, rule: defaultTapRule(ordinal: ordinal, tapCount: 2))
        case .oneFingerPress:
            return .oneFingerPress(id: id, type: self, rule: defaultOneFingerPressRule(ordinal: ordinal))
        case .oneFingerCustomPath:
            return .customPath(id: id, type: self, rule: defaultCustomPathRule(ordinal: ordinal))
        case .oneFingerDrawnPath:
            return .customPath(id: id, type: self, rule: defaultDrawnPathRule(ordinal: ordinal))
        case .twoFingerTouchStart:
            return .touchStart(id: id, type: self, rule: defaultTwoFingerTouchStartRule(ordinal: ordinal))
        case .twoFingerTap:
            return .tap(id: id, type: self, rule: defaultTwoFingerTapRule(ordinal: ordinal))
        case .tipTap:
            return .tipTap(id: id, type: self, rule: defaultTipTapRule(ordinal: ordinal))
        case .pinchIn, .pinchOut, .rotateLeft, .rotateRight:
            return .transform(id: id, type: self, rule: defaultTransformRule(ordinal: ordinal))
        case .freeformTwoFingerSwipe:
            return .multiFingerSwipe(id: id, type: self, rule: defaultFreeSwipeRule(ordinal: ordinal))
        case .regionTwoFingerSwipe:
            return .multiFingerSwipe(id: id, type: self, rule: defaultRegionSwipeRule(ordinal: ordinal))
        case .threeFingerForcePress:
            return .press(id: id, type: self, rule: defaultThreeFingerRule(ordinal: ordinal))
        case .upperLeftForcePress:
            return .press(id: id, type: self, rule: defaultUpperLeftRule(ordinal: ordinal))
        case .leftEdgeTwoFingerSwipe:
            return .swipe(id: id, type: self, rule: defaultSwipeRule(ordinal: ordinal))
        case .twoFingerHold:
            return .hold(id: id, type: self, rule: defaultHoldRule(ordinal: ordinal))
        case .upperRightForcePress:
            return .press(id: id, type: self, rule: defaultUpperRightRule(ordinal: ordinal))
        case .releaseLastFinger:
            return .release(id: id, type: self, rule: defaultReleaseRule(ordinal: ordinal))
        case .threeFingerTouch, .threeFingerTap, .threeFingerPress, .threeFingerSwipe,
             .threeFingerTipTap, .threeFingerTipSwipe, .thumbTwoFingerScale, .threeFingerDrawing:
            return defaultThreeFingerTrigger(id: id, ordinal: ordinal)
        case .fourFingerTouch, .fourFingerTap, .fourFingerPress, .fourFingerSwipe,
             .thumbThreeFingerScale, .fourFingerTipTap, .fourFingerDrawing:
            return defaultFourFingerTrigger(id: id, ordinal: ordinal)
        }
    }
}

private extension GestureTriggerType {
    func name(_ ordinal: Int) -> String {
        "\(displayName) \(ordinal)"
    }

    func defaultOneFingerRule(ordinal: Int) -> OneFingerGestureRule {
        OneFingerGestureRule(name: name(ordinal), isEnabled: true, cooldownMilliseconds: 650, action: commandAction())
    }

    func defaultOneFingerLongPressRule(ordinal: Int) -> HoldGestureRule {
        HoldGestureRule(
            name: name(ordinal),
            isEnabled: true,
            fingerCount: 1,
            holdMilliseconds: 800,
            maximumMovement: 0.04,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultCircleRule(ordinal: Int) -> CircleGestureRule {
        CircleGestureRule(
            name: name(ordinal),
            isEnabled: true,
            direction: .clockwise,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultShapeRule(_ shape: ShapeGestureKind, ordinal: Int) -> ShapeGestureRule {
        ShapeGestureRule(
            name: name(ordinal),
            isEnabled: true,
            shape: shape,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultCornerClickRule(ordinal: Int) -> CornerClickGestureRule {
        CornerClickGestureRule(
            name: name(ordinal),
            isEnabled: true,
            corner: .upperRight,
            clickKind: .click,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultTapRule(ordinal: Int, tapCount: Int) -> TapGestureRule {
        let tapWindow = tapCount == 2 ? 350 : 250
        let interval = tapCount == 2 ? 600 : 350
        let movement = tapCount == 2 ? 0.08 : 0.045
        return TapGestureRule(
            name: name(ordinal),
            isEnabled: true,
            tapCount: tapCount,
            maximumTapMilliseconds: tapWindow,
            doubleTapMaximumIntervalMilliseconds: interval,
            maximumMovement: movement,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
    }

    func defaultOneFingerPressRule(ordinal: Int) -> OneFingerPressGestureRule {
        OneFingerPressGestureRule(
            name: name(ordinal),
            isEnabled: true,
            pressKind: .click,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultCustomPathRule(ordinal: Int) -> CustomPathGestureRule {
        CustomPathGestureRule(
            name: name(ordinal),
            isEnabled: true,
            points: CustomPathGestureRule.defaultPoints,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultDrawnPathRule(ordinal: Int) -> CustomPathGestureRule {
        CustomPathGestureRule(
            name: name(ordinal),
            isEnabled: true,
            points: CustomPathGestureRule.defaultDrawnPathPoints,
            pointTolerance: 0.09,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
    }

    func defaultTwoFingerTouchStartRule(ordinal: Int) -> TouchStartGestureRule {
        TouchStartGestureRule(
            name: name(ordinal),
            isEnabled: true,
            fingerCount: 2,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
    }

    func defaultTwoFingerTapRule(ordinal: Int) -> TapGestureRule {
        TapGestureRule(
            name: name(ordinal),
            isEnabled: true,
            fingerCount: 2,
            tapCount: 1,
            maximumTapMilliseconds: 300,
            maximumMovement: 0.07,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
    }

    func defaultTipTapRule(ordinal: Int) -> TipTapGestureRule {
        TipTapGestureRule(
            name: name(ordinal),
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
    }

    func defaultTransformRule(ordinal: Int) -> TwoFingerTransformGestureRule {
        TwoFingerTransformGestureRule(
            name: name(ordinal),
            isEnabled: true,
            cooldownMilliseconds: 650,
            actions: GestureActionsCoding.scriptActions([commandAction()])
        )
    }

    func defaultFreeSwipeRule(ordinal: Int) -> MultiFingerSwipeGestureRule {
        MultiFingerSwipeGestureRule(
            name: name(ordinal),
            isEnabled: true,
            pathPreset: .right,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultRegionSwipeRule(ordinal: Int) -> MultiFingerSwipeGestureRule {
        MultiFingerSwipeGestureRule(
            name: name(ordinal),
            isEnabled: true,
            pathPreset: .right,
            startRegion: NormalizedRegion(minX: 0.0, maxX: 0.18, minY: 0.0, maxY: 1.0),
            endRegion: NormalizedRegion(minX: 0.38, maxX: 0.62, minY: 0.25, maxY: 0.75),
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultThreeFingerRule(ordinal: Int) -> PressGestureRule {
        PressGestureRule(
            name: name(ordinal),
            isEnabled: true,
            fingerCount: 3,
            minimumPressure: TrackpadPressureThreshold.forceClick,
            minimumForceMilliseconds: 80,
            cooldownMilliseconds: 650,
            region: nil,
            requiresClick: false,
            action: commandAction()
        )
    }

    func defaultUpperLeftRule(ordinal: Int) -> PressGestureRule {
        PressGestureRule(
            name: name(ordinal),
            isEnabled: true,
            fingerCount: 1,
            minimumPressure: TrackpadPressureThreshold.forceClick,
            minimumForceMilliseconds: 45,
            cooldownMilliseconds: 650,
            region: NormalizedRegion(minX: 0.0, maxX: 0.22, minY: 0.72, maxY: 1.0),
            requiresClick: true,
            action: commandAction()
        )
    }

    func defaultSwipeRule(ordinal: Int) -> SwipeGestureRule {
        SwipeGestureRule(
            name: name(ordinal),
            isEnabled: true,
            fingerCount: 2,
            edgeWidth: 0.18,
            minimumTravel: 0.25,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func defaultHoldRule(ordinal: Int) -> HoldGestureRule {
        HoldGestureRule(
            name: name(ordinal),
            isEnabled: true,
            fingerCount: 2,
            holdMilliseconds: 3_000,
            maximumMovement: 0.06,
            cooldownMilliseconds: 1_000,
            action: commandAction()
        )
    }

    func defaultUpperRightRule(ordinal: Int) -> PressGestureRule {
        PressGestureRule(
            name: name(ordinal),
            isEnabled: true,
            fingerCount: 1,
            minimumPressure: TrackpadPressureThreshold.forceClick,
            minimumForceMilliseconds: 45,
            cooldownMilliseconds: 900,
            region: NormalizedRegion(minX: 0.78, maxX: 1.0, minY: 0.72, maxY: 1.0),
            requiresClick: true,
            action: ScriptAction(language: .appleScript, script: DefaultScripts.toggleKeyboardViewer)
        )
    }

    func defaultReleaseRule(ordinal: Int) -> ReleaseGestureRule {
        ReleaseGestureRule(
            name: name(ordinal),
            isEnabled: true,
            previousFingerCount: .any,
            cooldownMilliseconds: 650,
            action: commandAction()
        )
    }

    func commandAction() -> ScriptAction {
        ScriptAction(language: .appleScript, script: DefaultScripts.placeholderAppleScript, timeoutSeconds: 5)
    }
}
