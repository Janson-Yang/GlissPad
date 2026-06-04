import AppKit
import GlissPadCore

@MainActor
final class ThreeFingerGestureControls {
    let touchEventPopup = NSPopUpButton()
    let touchTimingPopup = NSPopUpButton()
    let pressLevelPopup = NSPopUpButton()
    let pressureBiasPopup = NSPopUpButton()
    let pressTimingPopup = NSPopUpButton()
    let swipeDirectionPopup = NSPopUpButton()
    let swipePressModePopup = NSPopUpButton()
    let triggerTimingPopup = NSPopUpButton()
    let tipTapPositionPopup = NSPopUpButton()
    let tipTapReferencePopup = NSPopUpButton()
    let tipSwipeActiveFingerPopup = NSPopUpButton()
    let tipSwipeReferencePopup = NSPopUpButton()
    let tipSwipeDirectionPopup = NSPopUpButton()
    let tipSwipeTimingPopup = NSPopUpButton()
    let scaleDirectionPopup = NSPopUpButton()
    let scaleTimingPopup = NSPopUpButton()
    let thumbModePopup = NSPopUpButton()
    let drawingPathSourcePopup = NSPopUpButton()
    let drawingRecognitionPopup = NSPopUpButton()

    let touchHoldField = FormFactory.textField()
    let touchMovementField = FormFactory.textField()
    let touchRepeatIntervalField = FormFactory.textField()
    let commonInitialGapField = FormFactory.textField()
    let commonStableDurationField = FormFactory.textField()
    let tapCountField = FormFactory.textField()
    let tapDurationField = FormFactory.textField()
    let tapMovementField = FormFactory.textField()
    let tapIntervalField = FormFactory.textField()
    let pressMinimumField = FormFactory.textField()
    let pressForceField = FormFactory.textField()
    let pressBiasThresholdField = FormFactory.textField()
    let swipeTravelField = FormFactory.textField()
    let swipeVelocityField = FormFactory.textField()
    let directionToleranceField = FormFactory.textField()
    let tipTapCountField = FormFactory.textField()
    let tipTapDurationField = FormFactory.textField()
    let tipTapActiveMovementField = FormFactory.textField()
    let tipTapFixedMovementField = FormFactory.textField()
    let tipTapFixedHoldField = FormFactory.textField()
    let tipSwipeTravelField = FormFactory.textField()
    let tipSwipeVelocityField = FormFactory.textField()
    let tipSwipeDirectionToleranceField = FormFactory.textField()
    let tipSwipeFixedMovementField = FormFactory.textField()
    let tipSwipeFixedHoldField = FormFactory.textField()
    let scaleDeltaField = FormFactory.textField()
    let scaleVelocityField = FormFactory.textField()
    let drawingTemplateNameField = FormFactory.textField(width: 180)
    let drawingScoreField = FormFactory.textField()
    let drawingMinimumPathField = FormFactory.textField()
    let drawingMaximumDurationField = FormFactory.textField()
    let drawingResampleField = FormFactory.textField()

    let cancelOnMovementButton = NSButton(checkboxWithTitle: "Cancel on movement", target: nil, action: nil)
    let cancelOnPressButton = NSButton(checkboxWithTitle: "Cancel on press", target: nil, action: nil)
    let repeatWhileHoldingButton = NSButton(checkboxWithTitle: "Repeat while holding", target: nil, action: nil)
    let requireNoPressButton = NSButton(checkboxWithTitle: "Require no physical press", target: nil, action: nil)
    let fallbackWithoutPressureButton = NSButton(checkboxWithTitle: "Fallback without pressure data", target: nil, action: nil)
    let normalizeScaleButton = NSButton(checkboxWithTitle: "Normalize scale", target: nil, action: nil)
    let normalizeRotationButton = NSButton(checkboxWithTitle: "Normalize rotation", target: nil, action: nil)
}

@MainActor
extension GestureEditorWindowController {
    func configureThreeFingerControls() {
        configure(threeFingerControls.touchEventPopup, values: ThreeFingerTouchEvent.allCases)
        configure(threeFingerControls.touchTimingPopup, values: ThreeFingerTriggerTiming.allCases)
        configure(threeFingerControls.pressLevelPopup, values: ThreeFingerPressLevel.allCases)
        configure(threeFingerControls.pressureBiasPopup, values: ThreeFingerPressureBias.allCases)
        configure(threeFingerControls.pressTimingPopup, values: ThreeFingerPressTriggerTiming.allCases)
        configure(threeFingerControls.swipeDirectionPopup, values: ThreeFingerDirection.allCases)
        configure(threeFingerControls.swipePressModePopup, values: ThreeFingerSwipePressMode.allCases)
        configure(threeFingerControls.triggerTimingPopup, values: ThreeFingerTriggerTiming.allCases)
        configure(threeFingerControls.tipTapPositionPopup, values: ThreeFingerPosition.allCases)
        configure(threeFingerControls.tipTapReferencePopup, values: visibleFingerReferences(for: .trackpad))
        configure(threeFingerControls.tipSwipeActiveFingerPopup, values: ThreeFingerActiveFinger.allCases)
        configure(threeFingerControls.tipSwipeReferencePopup, values: visibleFingerReferences(for: .trackpad))
        configure(threeFingerControls.tipSwipeDirectionPopup, values: ThreeFingerDirection.allCases)
        configure(threeFingerControls.tipSwipeTimingPopup, values: ThreeFingerTriggerTiming.allCases)
        configure(threeFingerControls.scaleDirectionPopup, values: ThreeFingerScaleDirection.allCases)
        configure(threeFingerControls.scaleTimingPopup, values: ThreeFingerTriggerTiming.allCases)
        configure(threeFingerControls.thumbModePopup, values: ThreeFingerThumbDetectionMode.allCases)
        configure(threeFingerControls.drawingPathSourcePopup, values: ThreeFingerDrawingPathSource.allCases)
        configure(threeFingerControls.drawingRecognitionPopup, values: ThreeFingerDrawingRecognitionMode.allCases)
        configureThreeFingerCheckBoxes()
    }

    private func configure<T>(_ popup: NSPopUpButton, values: [T]) where T: DisplayNamed {
        popup.removeAllItems()
        popup.controlSize = .large
        popup.addItems(withTitles: values.map(\.displayName))
        popup.target = self
        popup.action = #selector(configurationControlChanged(_:))
    }

    func configureFingerReferencePopup(_ popup: NSPopUpButton, selected: ThreeFingerFingerReference) {
        configure(popup, values: visibleFingerReferences(for: selected))
        select(popup, value: selected)
    }

    private func visibleFingerReferences(for selected: ThreeFingerFingerReference) -> [ThreeFingerFingerReference] {
        selected == .touchOrder ? [.trackpad, .touchOrder] : [.trackpad]
    }

    private func configureThreeFingerCheckBoxes() {
        [
            threeFingerControls.cancelOnMovementButton,
            threeFingerControls.cancelOnPressButton,
            threeFingerControls.repeatWhileHoldingButton,
            threeFingerControls.requireNoPressButton,
            threeFingerControls.fallbackWithoutPressureButton,
            threeFingerControls.normalizeScaleButton,
            threeFingerControls.normalizeRotationButton
        ].forEach {
            $0.controlSize = .large
            $0.target = self
            $0.action = #selector(configurationControlChanged(_:))
        }
    }
}

protocol DisplayNamed {
    var displayName: String { get }
}

extension ThreeFingerTouchEvent: DisplayNamed {}
extension ThreeFingerPressLevel: DisplayNamed {}
extension ThreeFingerPressureBias: DisplayNamed {}
extension ThreeFingerPressTriggerTiming: DisplayNamed {}
extension ThreeFingerDirection: DisplayNamed {}
extension ThreeFingerSwipePressMode: DisplayNamed {}
extension ThreeFingerTriggerTiming: DisplayNamed {}
extension ThreeFingerPosition: DisplayNamed {}
extension ThreeFingerFingerReference: DisplayNamed {}
extension ThreeFingerActiveFinger: DisplayNamed {}
extension ThreeFingerScaleDirection: DisplayNamed {}
extension ThreeFingerThumbDetectionMode: DisplayNamed {}
extension ThreeFingerDrawingPathSource: DisplayNamed {}
extension ThreeFingerDrawingRecognitionMode: DisplayNamed {}
