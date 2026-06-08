import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func visibleAction() throws -> GestureAction {
        guard let action = selectedGestureAction() else {
            throw GUIValidationError.invalidField("selected action")
        }
        switch action {
        case .script:
            return try visibleScriptAction()
        case .keyboardShortcut:
            return try visibleKeyboardShortcutAction()
        case .testHUD:
            return try visibleTestHUDAction()
        case .latency:
            return try visibleLatencyAction()
        }
    }

    func currentActionTimeout() -> TimeInterval {
        let actions = selectedSlot.actions(in: configuration)
        guard actions.indices.contains(selectedAction.index),
              let timeout = actions[selectedAction.index].timeoutSeconds else { return 5 }
        return timeout
    }

    func visibleRegion() throws -> NormalizedRegion? {
        let values = try [
            doubleValue(regionFields.minX, name: "region minX"),
            doubleValue(regionFields.maxX, name: "region maxX"),
            doubleValue(regionFields.minY, name: "region minY"),
            doubleValue(regionFields.maxY, name: "region maxY")
        ]
        let fullTrackpadTypes: [GestureTriggerType] = [
            .oneFingerTouchStart,
            .oneFingerLongPress,
            .oneFingerTap,
            .oneFingerDoubleTap,
            .twoFingerTouchStart,
            .twoFingerTap,
            .tipTap,
            .pinchIn,
            .pinchOut,
            .rotateLeft,
            .rotateRight,
            .threeFingerForcePress,
            .twoFingerHold,
            .threeFingerTouch,
            .threeFingerTap,
            .threeFingerPress,
            .threeFingerSwipe,
            .threeFingerTipTap,
            .threeFingerTipSwipe,
            .thumbTwoFingerScale,
            .threeFingerDrawing,
            .fourFingerTouch,
            .fourFingerTap,
            .fourFingerPress,
            .fourFingerSwipe,
            .thumbThreeFingerScale,
            .fourFingerTipTap,
            .fourFingerDrawing,
            .fiveFingerTouch,
            .fiveFingerTap,
            .fiveFingerPress,
            .thumbFourFingerScale,
            .fiveFingerSwipe,
            .fiveFingerDrawing,
            .wholeHandTap
        ]
        if let type = selectedSlot.trigger(in: configuration)?.type,
           values == [0, 1, 0, 1],
           fullTrackpadTypes.contains(type) {
            return nil
        }
        return NormalizedRegion(minX: values[0], maxX: values[1], minY: values[2], maxY: values[3])
    }

    func selectedReleaseFingerCount() throws -> ReleaseFingerCount {
        guard let title = releaseFingerCountPopup.selectedItem?.title,
              let count = ReleaseFingerCount.menuOptions.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("fingers before release")
        }
        return count
    }

    func selectedCircleDirection() throws -> CircleDirection {
        guard let title = circleDirectionPopup.selectedItem?.title,
              let direction = CircleDirection.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("circle direction")
        }
        return direction
    }

    func selectedTrackpadCorner() throws -> TrackpadCorner {
        guard let title = cornerPresetPopup.selectedItem?.title,
              let corner = TrackpadCorner.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("corner")
        }
        return corner
    }

    func selectedCornerClickKind() throws -> CornerClickKind {
        guard let title = cornerClickKindPopup.selectedItem?.title,
              let kind = CornerClickKind.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("click type")
        }
        return kind
    }

    func selectedOneFingerPressKind() throws -> OneFingerPressKind {
        guard let title = oneFingerPressKindPopup.selectedItem?.title,
              let kind = OneFingerPressKind.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("press type")
        }
        return kind
    }

    func selectedHoldPressKind() throws -> HoldPressKind {
        guard let title = holdPressKindPopup.selectedItem?.title,
              let kind = HoldPressKind.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("hold press type")
        }
        return kind
    }

    func selectedHoldTriggerTiming() throws -> HoldTriggerTiming {
        guard let title = holdTriggerTimingPopup.selectedItem?.title,
              let timing = HoldTriggerTiming.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("hold trigger timing")
        }
        return timing
    }

    func selectedTipTapActiveFinger() throws -> TipTapActiveFinger {
        guard let title = tipTapActiveFingerPopup.selectedItem?.title,
              let finger = TipTapActiveFinger.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("tip tap active finger")
        }
        return finger
    }

    func doubleValue(_ field: NSTextField, name: String) throws -> Double {
        guard let value = Double(field.stringValue) else {
            throw GUIValidationError.invalidField(name)
        }
        return value
    }

    func intValue(_ field: NSTextField, name: String) throws -> Int {
        guard let value = Int(field.stringValue) else {
            throw GUIValidationError.invalidField(name)
        }
        return value
    }

    func nonEmptyString(_ field: NSTextField, name: String) throws -> String {
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw GUIValidationError.invalidField(name)
        }
        return value
    }
}

enum GUIValidationError: Error, CustomStringConvertible {
    case invalidField(String)

    var description: String {
        switch self {
        case .invalidField(let name):
            return "Invalid \(name)."
        }
    }
}
